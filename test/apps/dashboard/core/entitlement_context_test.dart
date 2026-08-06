import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/entitlements/licensing_failure.dart';

/// The client-side half of the entitlement platform.
///
/// These assertions are the Dart mirror of the rules the database regression
/// suite proves server-side, and they exist because this object decides what an
/// operator can SEE. Getting it wrong does not open a hole — every write is
/// re-checked by a trigger — but it does hide a module the server would have
/// served, which is indistinguishable from a downgrade nobody agreed to.

EntitlementContext _context({
  String mode = 'enforcing',
  Map<String, Map<String, dynamic>> features = const {},
  Map<String, dynamic> license = const {
    'plan_key': 'starter',
    'status': 'active',
  },
}) {
  return EntitlementContext.fromRpc({
    'license': license,
    'features': features,
    'enforcement_mode': mode,
    'resolved_at': DateTime.now().toIso8601String(),
  });
}

void main() {
  group('EntitlementContext.allows', () {
    test('a null feature key is always allowed', () {
      expect(_context().allows(null), isTrue);
    });

    test('while enforcement is off, everything is allowed', () {
      // Deploy day: the server enforces nothing, so the sidebar must not
      // pretend otherwise. Hiding a module the backend would happily serve is
      // its own kind of bug.
      final context = _context(
        mode: 'off',
        features: {
          'wallet': {'value': false, 'source': 'plan', 'value_type': 'boolean'},
        },
      );
      expect(context.allows('wallet'), isTrue);
      expect(context.isEnforcing, isFalse);
    });

    test('shadow mode allows too — it observes, it does not block', () {
      final context = _context(
        mode: 'shadow',
        features: {
          'wallet': {'value': false, 'source': 'plan', 'value_type': 'boolean'},
        },
      );
      expect(context.allows('wallet'), isTrue);
    });

    test('while enforcing, a false feature is refused', () {
      final context = _context(
        features: {
          'wallet': {'value': false, 'source': 'plan', 'value_type': 'boolean'},
          'trips': {'value': true, 'source': 'plan', 'value_type': 'boolean'},
        },
      );
      expect(context.allows('wallet'), isFalse);
      expect(context.allows('trips'), isTrue);
    });

    test('an unknown key is allowed, never hidden on missing data', () {
      // The catalog is data and can grow without a deploy, so a build that has
      // never heard of a key must fail open rather than blank a module out.
      expect(_context().allows('feature_from_the_future'), isTrue);
    });

    test('the unknown context allows everything', () {
      // The state before the document loads, and after a failed load.
      expect(EntitlementContext.unknown.allows('wallet'), isTrue);
      expect(EntitlementContext.unknown.isLoaded, isFalse);
    });
  });

  group('hidden vs locked', () {
    test('purchasable and real ⇒ locked, so it can be sold', () {
      final context = _context(
        features: {
          'wallet': {
            'value': false,
            'source': 'plan',
            'value_type': 'boolean',
            'is_public': true,
            'enforcement_status': 'enforced',
          },
        },
      );
      expect(context.isLocked('wallet'), isTrue);
    });

    test(
      'unpurchasable ⇒ hidden, because an upgrade prompt would be noise',
      () {
        final context = _context(
          features: {
            'api_access': {
              'value': false,
              'source': 'default',
              'value_type': 'boolean',
              'is_public': false,
              'enforcement_status': 'declared',
            },
          },
        );
        expect(context.isLocked('api_access'), isFalse);
      },
    );

    test('declared but public ⇒ still hidden: the code cannot deliver it', () {
      final context = _context(
        features: {
          'marketing': {
            'value': false,
            'source': 'default',
            'value_type': 'boolean',
            'is_public': true,
            'enforcement_status': 'declared',
          },
        },
      );
      expect(context.isLocked('marketing'), isFalse);
    });

    test('an allowed feature is never locked', () {
      final context = _context(
        features: {
          'wallet': {
            'value': true,
            'source': 'plan',
            'value_type': 'boolean',
            'is_public': true,
            'enforcement_status': 'enforced',
          },
        },
      );
      expect(context.isLocked('wallet'), isFalse);
    });
  });

  group('limit values', () {
    test('"unlimited" is a string, never -1 and never null', () {
      final feature = ResolvedFeature.fromJson('max_drivers', {
        'value': 'unlimited',
        'value_type': 'limit',
        'source': 'plan',
        'used': 12,
      });
      expect(feature.isUnlimited, isTrue);
      expect(feature.limit, isNull);
      expect(feature.isOverLimit, isFalse);
      expect(feature.isOn, isTrue);
    });

    test('over-limit is reported, not clamped', () {
      // Downgrading from 50 to 10 deletes nothing; the office is genuinely over
      // by 40 and keeps all 50. The console has to be able to say so.
      final feature = ResolvedFeature.fromJson('max_drivers', {
        'value': 10,
        'value_type': 'limit',
        'source': 'plan',
        'used': 50,
      });
      expect(feature.limit, 10);
      expect(feature.isOverLimit, isTrue);
    });

    test('a zero limit is falsey, so the module reads as off', () {
      final feature = ResolvedFeature.fromJson('max_drivers', {
        'value': 0,
        'value_type': 'limit',
        'source': 'license_hold',
      });
      expect(feature.isOn, isFalse);
    });
  });

  group('the ladder is reported, not just its result', () {
    test('an override defeated by a dependency reports BOTH facts', () {
      // The override IS honoured at rung 2 and then defeated at the dependency
      // gate. Showing only one of the two looks like the system ignored the
      // operator who granted it.
      final feature = ResolvedFeature.fromJson('cashback', {
        'value': false,
        'value_type': 'boolean',
        'source': 'override',
        'blocked_by': 'wallet',
      });
      expect(feature.source, 'override');
      expect(feature.blockedBy, 'wallet');
      expect(feature.isOn, isFalse);
    });
  });

  group('LicenseSummary', () {
    test('past_due and grace need attention but are not holds', () {
      for (final status in ['past_due', 'grace']) {
        final license = LicenseSummary.fromJson({'status': status});
        expect(license.needsAttention, isTrue, reason: status);
        expect(license.isHeld, isFalse, reason: status);
      }
    });

    test('suspended, cancelled and expired are holds', () {
      for (final status in ['suspended', 'cancelled', 'expired']) {
        expect(LicenseSummary.fromJson({'status': status}).isHeld, isTrue);
      }
    });

    test('an office with no licence row is not an error state', () {
      final license = LicenseSummary.fromJson({'status': 'none'});
      expect(license.needsAttention, isFalse);
      expect(license.statusLabelAr, 'بدون ترخيص');
    });
  });

  group('LicensingFailure', () {
    test('a non-licensing error is not claimed', () {
      final error = PostgrestException(message: 'insufficient_wallet_balance');
      expect(LicensingFailure.tryParse(error), isNull);
    });

    test('a quota refusal carries the numbers across', () {
      // This is what makes the block specific: the named limit, the real
      // numbers and the plan — never the words "quota_exceeded".
      final error = PostgrestException(
        message: 'quota_exceeded',
        details:
            '{"allowed": false, "limit": 12, "used": 12, "feature": '
            '"max_drivers", "plan_key": "starter"}',
      );
      final failure = LicensingFailure.tryParse(error)!;
      expect(failure.code, LicensingFailure.quotaExceeded);
      expect(failure.isQuota, isTrue);
      expect(failure.featureKey, 'max_drivers');
      expect(failure.limit, 12);
      expect(failure.used, 12);
      expect(failure.planKey, 'starter');
    });

    test('an unparseable detail still produces a usable refusal', () {
      final error = PostgrestException(message: 'feature_not_licensed');
      final failure = LicensingFailure.tryParse(error)!;
      expect(failure.code, LicensingFailure.featureNotLicensed);
      expect(failure.message, isNotEmpty);
      expect(failure.featureKey, isNull);
    });

    test('each refusal code has its own sentence', () {
      // "You don't have permission" when the truth is "your plan doesn't
      // include this" is the difference between a ticket and a sale.
      final messages = LicensingFailure.messages.values.toSet();
      expect(messages.length, LicensingFailure.messages.length);
      expect(
        LicensingFailure.messages[LicensingFailure.notAuthorized],
        isNot(LicensingFailure.messages[LicensingFailure.featureNotLicensed]),
      );
    });

    test('a suspension refusal says what still works', () {
      expect(
        LicensingFailure.messages[LicensingFailure.licenseSuspended],
        contains('ما هو قائم يكمل'),
      );
    });
  });
}

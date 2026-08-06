import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/refund_request.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_vocabulary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/usecases/wallet_usecases.dart';

/// The rules, tested where they can be tested without a database.
///
/// Every one of these is *also* enforced server-side — the UI is not a security
/// boundary and the SQL regression suite proves the server's copy. What is
/// asserted here is that the operator is stopped early, in Arabic, in the dialog,
/// rather than after a round trip that comes back saying `invalid_amount`.
void main() {
  group('AdjustWalletUseCase', () {
    late _RecordingRepository repository;
    late AdjustWalletUseCase adjust;

    setUp(() {
      repository = _RecordingRepository();
      adjust = AdjustWalletUseCase(repository);
    });

    test('rejects a zero or negative amount', () async {
      expect(
        () => adjust(
          kind: WalletKind.cashback,
          clientId: 'c1',
          amount: 0,
          category: 'promotion',
          reason: 'اختبار',
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
      expect(repository.calls, isEmpty);
    });

    test('rejects a blank reason', () async {
      expect(
        () => adjust(
          kind: WalletKind.cashback,
          clientId: 'c1',
          amount: 50,
          category: 'promotion',
          reason: '   ',
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('rejects a category that does not belong to the kind', () async {
      // `clawback` is a debit reason; offering it on a cashback would produce a
      // row the reporting layer could not group.
      expect(
        () => adjust(
          kind: WalletKind.cashback,
          clientId: 'c1',
          amount: 50,
          category: 'clawback',
          reason: 'اختبار',
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('rejects a kind that is not an adjustment', () async {
      expect(
        () => adjust(
          kind: WalletKind.refund,
          clientId: 'c1',
          amount: 50,
          category: 'trip_cancelled',
          reason: 'اختبار',
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('refuses a debit larger than the available balance', () async {
      expect(
        () => adjust(
          kind: WalletKind.manualDebit,
          clientId: 'c1',
          amount: 120,
          category: 'correction',
          reason: 'اختبار',
          requestKey: 'k',
          wallet: _wallet(balance: 100),
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('refuses a debit on a frozen wallet but allows a credit', () async {
      final frozen = _wallet(balance: 100, status: WalletStatus.frozen);

      expect(
        () => adjust(
          kind: WalletKind.manualDebit,
          clientId: 'c1',
          amount: 10,
          category: 'correction',
          reason: 'اختبار',
          requestKey: 'k',
          wallet: frozen,
        ),
        throwsA(isA<WalletRuleViolation>()),
      );

      // Credits still land: you must always be able to refund someone.
      await adjust(
        kind: WalletKind.manualCredit,
        clientId: 'c1',
        amount: 10,
        category: 'goodwill',
        reason: 'اختبار',
        requestKey: 'k2',
        wallet: frozen,
      );
      expect(repository.calls, ['credit']);
    });

    test('rounds to two decimals before sending', () async {
      await adjust(
        kind: WalletKind.cashback,
        clientId: 'c1',
        amount: 10.005,
        category: 'promotion',
        reason: 'اختبار',
        requestKey: 'k',
      );
      expect(repository.lastAmount, 10.01);
    });

    test('routes each kind to its own RPC, never a shared one', () async {
      for (final kind in const [
        WalletKind.cashback,
        WalletKind.manualCredit,
        WalletKind.manualDebit,
      ]) {
        await adjust(
          kind: kind,
          clientId: 'c1',
          amount: 5,
          category: WalletCategories.forKind(kind).first.code,
          reason: 'اختبار',
          requestKey: 'k-${kind.dbValue}',
          wallet: _wallet(balance: 500),
        );
      }
      expect(repository.calls, ['cashback', 'credit', 'debit']);
    });
  });

  group('ReverseWalletTransactionUseCase', () {
    late _RecordingRepository repository;
    late ReverseWalletTransactionUseCase reverse;

    setUp(() {
      repository = _RecordingRepository();
      reverse = ReverseWalletTransactionUseCase(repository);
    });

    test('refuses to reverse a reversal', () async {
      expect(
        () => reverse(
          transaction: _entry(kind: WalletKind.reversal, amount: -50),
          reason: 'اختبار',
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('refuses an already-reversed entry', () async {
      expect(
        () => reverse(
          transaction: _entry(
            kind: WalletKind.cashback,
            amount: 50,
            status: WalletEntryStatus.reversed,
          ),
          reason: 'اختبار',
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('refuses when the credit has been spent, rather than going negative', () async {
      // §5.3: the honest outcome is a refusal plus an out-of-band receivable,
      // not a negative balance the platform has no instrument to collect.
      expect(
        () => reverse(
          transaction: _entry(kind: WalletKind.cashback, amount: 100),
          reason: 'اختبار',
          requestKey: 'k',
          wallet: _wallet(balance: 20),
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('reverses a debit without a balance check', () async {
      // Reversing a debit gives money back; there is nothing to be short of.
      await reverse(
        transaction: _entry(kind: WalletKind.manualDebit, amount: -100),
        reason: 'اختبار',
        requestKey: 'k',
        wallet: _wallet(balance: 0),
      );
      expect(repository.calls, ['reverse']);
    });
  });

  group('CreateRefundUseCase', () {
    late _RecordingRepository repository;
    late CreateRefundUseCase create;

    setUp(() {
      repository = _RecordingRepository();
      create = CreateRefundUseCase(repository);
    });

    test('caps the refund at the booking’s remaining refundable amount', () async {
      expect(
        () => create(
          booking: _bookingTarget(refundable: 200),
          amount: 250,
          category: 'trip_cancelled',
          reason: 'اختبار',
          settlement: RefundSettlement.wallet,
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('allows a partial refund and leaves capacity behind', () async {
      await create(
        booking: _bookingTarget(refundable: 200),
        amount: 80,
        category: 'trip_cancelled',
        reason: 'اختبار',
        settlement: RefundSettlement.wallet,
        requestKey: 'k',
      );
      expect(repository.lastAmount, 80);
    });

    test('refuses a wallet settlement for a guest booking', () async {
      expect(
        () => create(
          booking: _bookingTarget(refundable: 200),
          amount: 50,
          category: 'other',
          reason: 'اختبار',
          settlement: RefundSettlement.wallet,
          requestKey: 'k',
          hasClient: false,
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('allows a cash settlement for a guest booking', () async {
      await create(
        booking: _bookingTarget(refundable: 200),
        amount: 50,
        category: 'other',
        reason: 'اختبار',
        settlement: RefundSettlement.cash,
        requestKey: 'k',
        hasClient: false,
      );
      expect(repository.calls, ['createRefund']);
    });
  });

  group('DecideRefundUseCase', () {
    late _RecordingRepository repository;
    late DecideRefundUseCase decide;

    setUp(() {
      repository = _RecordingRepository();
      decide = DecideRefundUseCase(repository);
    });

    test('refuses to decide a request that is already closed', () async {
      expect(
        () => decide(
          refund: _refund(amount: 100, status: RefundStatus.settled),
          approve: true,
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('refuses to approve more than was requested', () async {
      expect(
        () => decide(
          refund: _refund(amount: 100),
          approve: true,
          approvedAmount: 150,
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });

    test('allows approving less than was requested', () async {
      await decide(
        refund: _refund(amount: 100),
        approve: true,
        approvedAmount: 60,
        requestKey: 'k',
      );
      expect(repository.lastAmount, 60);
    });

    test('requires a reason to reject', () async {
      expect(
        () => decide(
          refund: _refund(amount: 100),
          approve: false,
          requestKey: 'k',
        ),
        throwsA(isA<WalletRuleViolation>()),
      );
    });
  });

  group('Vocabulary', () {
    test('every category offered for a kind belongs to that kind', () {
      for (final kind in WalletKind.active) {
        for (final category in WalletCategories.forKind(kind)) {
          expect(
            WalletCategories.labelOf(category.code),
            isNot(category.code),
            reason: '${category.code} has no label',
          );
        }
      }
    });

    test('the reserved V2 kinds are declared but offered nowhere', () {
      // They exist in the database CHECK on day one so V2 needs no constraint
      // migration — but nothing in V1 may put them in front of an operator.
      expect(WalletKind.active, isNot(contains(WalletKind.walletSpend)));
      expect(WalletKind.active, isNot(contains(WalletKind.walletTopup)));
    });

    test('an unknown category code falls back to itself, never to blank', () {
      expect(WalletCategories.labelOf('a_new_server_side_reason'),
          'a_new_server_side_reason');
    });
  });

  group('WalletLedgerFilters', () {
    test('an empty filter set serialises to an empty object', () {
      expect(const WalletLedgerFilters().toJson(), isEmpty);
      expect(const WalletLedgerFilters().isEmpty, isTrue);
    });

    test('kinds and statuses serialise as their database values', () {
      final json = WalletLedgerFilters(
        kinds: {WalletKind.refund, WalletKind.manualDebit},
        statuses: {WalletEntryStatus.reversed},
      ).toJson();

      expect(json['kinds'], containsAll(['refund', 'manual_debit']));
      expect(json['statuses'], ['reversed']);
    });

    test('direction collapses to one string the server understands', () {
      expect(
        const WalletLedgerFilters(creditsOnly: true).toJson()['direction'],
        'credit',
      );
      expect(
        const WalletLedgerFilters(creditsOnly: false).toJson()['direction'],
        'debit',
      );
      // Absent, not "both": a present key would be a filter.
      expect(
        const WalletLedgerFilters().toJson().containsKey('direction'),
        isFalse,
      );
    });

    test('clearing a filter removes it rather than zeroing it', () {
      final filters = WalletLedgerFilters(
        from: DateTime(2026, 8, 1),
        creditsOnly: true,
      );
      final cleared = filters.copyWith(clearDates: true, clearDirection: true);

      expect(cleared.toJson().containsKey('date_from'), isFalse);
      expect(cleared.toJson().containsKey('direction'), isFalse);
    });

    test('a blank search string is not sent as a filter', () {
      expect(
        const WalletLedgerFilters(search: '   ').toJson().containsKey('search'),
        isFalse,
      );
    });
  });
}

// ── Fixtures ────────────────────────────────────────────────────────────────

Wallet _wallet({
  required double balance,
  WalletStatus status = WalletStatus.active,
}) => Wallet(
  exists: true,
  id: 'w1',
  balance: balance,
  availableBalance: balance,
  status: status,
  frozenReason: status == WalletStatus.frozen ? 'اختبار' : null,
);

WalletTransaction _entry({
  required WalletKind kind,
  required double amount,
  WalletEntryStatus status = WalletEntryStatus.posted,
}) => WalletTransaction(
  id: 't1',
  seq: 1,
  kind: kind,
  category: 'promotion',
  source: WalletSource.dashboard,
  amount: amount,
  balanceBefore: 0,
  balanceAfter: amount,
  status: status,
  reason: 'اختبار',
  performedByName: 'مشغّل',
  createdAt: DateTime(2026, 8, 6),
  clientId: 'c1',
);

RefundableBooking _bookingTarget({required double refundable}) =>
    RefundableBooking(
      bookingId: 'b1',
      status: 'confirmed',
      paidAmount: refundable,
      refundableAmount: refundable,
    );

RefundRequest _refund({
  required double amount,
  RefundStatus status = RefundStatus.pending,
}) => RefundRequest(
  id: 'r1',
  clientId: 'c1',
  amount: amount,
  currency: 'EGP',
  status: status,
  category: 'other',
  reason: 'اختبار',
  source: 'client',
  createdAt: DateTime(2026, 8, 6),
);

/// Records what reached the repository, so a test can assert that a refused
/// request never became a network call.
class _RecordingRepository implements WalletRepository {
  final List<String> calls = [];
  double? lastAmount;

  @override
  Future<WalletTransaction> grantCashback({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async {
    calls.add('cashback');
    lastAmount = amount;
    return _entry(kind: WalletKind.cashback, amount: amount);
  }

  @override
  Future<WalletTransaction> credit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async {
    calls.add('credit');
    lastAmount = amount;
    return _entry(kind: WalletKind.manualCredit, amount: amount);
  }

  @override
  Future<WalletTransaction> debit({
    required String clientId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required String requestKey,
  }) async {
    calls.add('debit');
    lastAmount = amount;
    return _entry(kind: WalletKind.manualDebit, amount: -amount);
  }

  @override
  Future<WalletTransaction> reverse({
    required String transactionId,
    required String reason,
    required String category,
    required String requestKey,
  }) async {
    calls.add('reverse');
    return _entry(kind: WalletKind.reversal, amount: -1);
  }

  @override
  Future<RefundRequest> createRefund({
    required String bookingId,
    required double amount,
    required String category,
    required String reason,
    String? notes,
    required RefundSettlement settlement,
    required String requestKey,
  }) async {
    calls.add('createRefund');
    lastAmount = amount;
    return _refund(amount: amount);
  }

  @override
  Future<RefundRequest> decideRefund({
    required String refundId,
    required bool approve,
    double? approvedAmount,
    RefundSettlement settlement = RefundSettlement.wallet,
    String? reason,
    required String requestKey,
  }) async {
    calls.add('decideRefund');
    lastAmount = approvedAmount;
    return _refund(amount: approvedAmount ?? 0, status: RefundStatus.settled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

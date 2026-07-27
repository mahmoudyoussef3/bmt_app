import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/live_location/domain/entities/location_sharing_health.dart';

/// The card that reports position sharing used to derive its headline from
/// whether a `Timer` existed, and said "مشاركة الموقع تلقائياً كل 30 ثانية" for
/// as long as one did. That is a claim about the app's intent, not about the
/// trip: a captain in a tunnel, or with location permission revoked mid-trip,
/// read a card promising the client's map was live while every send had failed
/// for twenty minutes — with the GPS card directly beneath it saying "قديم".
///
/// These tests pin the rule that replaced it: health is a function of when a
/// fix last actually landed.
void main() {
  final now = DateTime(2026, 7, 28, 14, 0);

  LocationSharingStatus statusAt({
    required bool sharing,
    Duration? sinceLastFix,
  }) {
    return LocationSharingStatus.evaluate(
      isAutoSharing: sharing,
      lastSentAt: sinceLastFix == null ? null : now.subtract(sinceLastFix),
      now: now,
    );
  }

  group('reporting health', () {
    test('not sharing reads as stopped, and never as live', () {
      final status = statusAt(sharing: false);

      expect(status.health, LocationSharingHealth.off);
      expect(status.isHealthy, isFalse);
      expect(status.headline, 'المشاركة التلقائية متوقفة');
    });

    test('sharing with no fix yet reads as acquiring, not as live', () {
      final status = statusAt(sharing: true);

      expect(status.health, LocationSharingHealth.acquiring);
      expect(status.isHealthy, isFalse);
      // Must not promise a cadence it has not achieved even once.
      expect(status.headline, isNot(contains('30')));
    });

    test('a fix inside the window reads as live and states the cadence', () {
      final status = statusAt(sharing: true, sinceLastFix: kAutoLocationInterval);

      expect(status.health, LocationSharingHealth.live);
      expect(status.isHealthy, isTrue);
      expect(status.headline, contains('${kAutoLocationInterval.inSeconds}'));
    });

    test('a fix older than the stale threshold reads as stale — this is the '
        'defect: the timer is still running and the card used to say so', () {
      final status = statusAt(
        sharing: true,
        sinceLastFix: kLocationStaleAfter + const Duration(seconds: 1),
      );

      expect(status.health, LocationSharingHealth.stale);
      expect(status.isHealthy, isFalse);
      // The headline must name the failure, not the intent.
      expect(status.headline, contains('تعذّر'));
      expect(status.headline, isNot(contains('${kAutoLocationInterval.inSeconds} ثانية')));
    });

    test('the boundary is inclusive of live, exclusive of stale', () {
      expect(
        statusAt(
          sharing: true,
          sinceLastFix: kLocationStaleAfter - const Duration(seconds: 1),
        ).health,
        LocationSharingHealth.live,
      );
      expect(
        statusAt(sharing: true, sinceLastFix: kLocationStaleAfter).health,
        LocationSharingHealth.stale,
      );
    });

    test('a long outage still reports the age rather than going silent', () {
      final status = statusAt(
        sharing: true,
        sinceLastFix: const Duration(hours: 1, minutes: 5),
      );

      expect(status.health, LocationSharingHealth.stale);
      expect(status.age, const Duration(hours: 1, minutes: 5));
      expect(status.headline, contains('1س 5د'));
    });
  });

  group('staleness threshold', () {
    test('is derived from the publish cadence, so the two cannot drift', () {
      // If someone changes the cadence, the threshold follows. A literal here
      // is how a 30 s producer ends up judged against a 90 s rule nobody
      // remembered to update.
      expect(kLocationStaleAfter, kAutoLocationInterval * 3);
    });

    test('tolerates one missed tick but not two', () {
      expect(kAutoLocationInterval * 2 < kLocationStaleAfter, isTrue);
      expect(kAutoLocationInterval * 3 <= kLocationStaleAfter, isTrue);
    });
  });

  group('age formatting', () {
    test('reads naturally in Arabic across the ranges', () {
      expect(formatLocationAge(const Duration(seconds: 20)), 'منذ أقل من دقيقة');
      expect(formatLocationAge(const Duration(minutes: 7)), 'منذ 7 دقيقة');
      expect(formatLocationAge(const Duration(hours: 2)), 'منذ 2 ساعة');
      expect(formatLocationAge(const Duration(hours: 2, minutes: 30)), 'منذ 2س 30د');
    });
  });
}

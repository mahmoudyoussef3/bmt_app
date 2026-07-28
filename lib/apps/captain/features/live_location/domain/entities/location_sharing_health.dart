/// How often an active trip reports its position automatically.
///
/// Thirty seconds is the platform's tracking cadence (`SYSTEM_FLOW.md`): the
/// client's map merges realtime inserts with a short poll fallback, so a denser
/// producer cadence only ever sharpens the vehicle's movement, never degrades
/// it. It stays cheap enough to run foreground for a whole trip: one high-
/// accuracy fix every 30 s while the captain has the execution screen open.
///
/// Declared here, in the domain, because the staleness threshold below is
/// derived from it and the two must never drift apart. `LiveLocationCubit`
/// re-exports it, so every existing `kAutoLocationInterval` import still
/// resolves.
const Duration kAutoLocationInterval = Duration(seconds: 30);

/// How the captain's position reporting is actually doing — derived from when a
/// fix last reached the server, never from whether a timer happens to exist.
///
/// The distinction is the whole point. The auto-share card used to say
/// "مشاركة الموقع تلقائياً كل 30 ثانية" for as long as the timer was running,
/// which is a statement about the app's intentions rather than about the trip.
/// A captain in a tunnel, with location permission revoked mid-trip, or on a
/// dead signal kept reading a card that claimed the client's map was moving
/// while every send had failed for twenty minutes — and the GPS card directly
/// below it said "قديم" at the same time. Two cards on one screen disagreeing
/// about the same fact is worse than either of them being absent.
enum LocationSharingHealth {
  /// Reporting is not running — the trip has not departed, or it has ended.
  off,

  /// Running, but no fix has landed yet. The first send is in flight.
  acquiring,

  /// A fix landed recently enough that the client's map is genuinely live.
  live,

  /// Running, but the last successful fix is older than the cadence allows.
  /// Sends are failing; the client's map is going stale right now.
  stale,
}

/// How long after a successful send the reporting stops counting as [live].
///
/// Two intervals plus a margin: one missed tick is a bad moment, two in a row
/// means the sends are not landing. Tied to [kAutoLocationInterval] rather than
/// written as a literal so changing the cadence cannot silently leave this
/// threshold behind.
final Duration kLocationStaleAfter =
    kAutoLocationInterval * 2 + kAutoLocationInterval;

/// Resolves reporting health, and the sentence the captain reads for it.
///
/// Pure and clock-injected so the thresholds are testable without waiting.
class LocationSharingStatus {
  const LocationSharingStatus._(this.health, this.headline, this.age);

  final LocationSharingHealth health;

  /// The one line the captain reads at a glance. Never claims a cadence the
  /// trip is not actually achieving.
  final String headline;

  /// Age of the last successful fix, null when there has not been one.
  final Duration? age;

  bool get isHealthy => health == LocationSharingHealth.live;

  factory LocationSharingStatus.evaluate({
    required bool isAutoSharing,
    required DateTime? lastSentAt,
    required DateTime now,
  }) {
    if (!isAutoSharing) {
      return const LocationSharingStatus._(
        LocationSharingHealth.off,
        'المشاركة التلقائية متوقفة',
        null,
      );
    }

    if (lastSentAt == null) {
      return const LocationSharingStatus._(
        LocationSharingHealth.acquiring,
        'جارٍ تحديد موقعك...',
        null,
      );
    }

    final age = now.difference(lastSentAt);
    if (age < kLocationStaleAfter) {
      return LocationSharingStatus._(
        LocationSharingHealth.live,
        'يتم إرسال موقعك كل ${kAutoLocationInterval.inSeconds} ثانية',
        age,
      );
    }

    return LocationSharingStatus._(
      LocationSharingHealth.stale,
      'تعذّر إرسال موقعك — آخر إرسال ${formatLocationAge(age)}',
      age,
    );
  }
}

/// "منذ 4 دقائق" and friends. Kept beside the health rules because the two are
/// read together and a mismatch between them is exactly the confusion this
/// file exists to prevent.
String formatLocationAge(Duration age) {
  if (age.inSeconds < 60) return 'منذ أقل من دقيقة';
  if (age.inMinutes < 60) return 'منذ ${age.inMinutes} دقيقة';
  final hours = age.inHours;
  final minutes = age.inMinutes.remainder(60);
  return minutes == 0 ? 'منذ $hours ساعة' : 'منذ $hoursس $minutesد';
}

const Duration kAutoLocationInterval = Duration(seconds: 30);

enum LocationSharingHealth { off, acquiring, live, stale }

final Duration kLocationStaleAfter =
    kAutoLocationInterval * 2 + kAutoLocationInterval;

class LocationSharingStatus {
  const LocationSharingStatus._(this.health, this.headline, this.age);

  final LocationSharingHealth health;

  final String headline;

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

String formatLocationAge(Duration age) {
  if (age.inSeconds < 60) return 'منذ أقل من دقيقة';
  if (age.inMinutes < 60) return 'منذ ${age.inMinutes} دقيقة';
  final hours = age.inHours;
  final minutes = age.inMinutes.remainder(60);
  return minutes == 0 ? 'منذ $hours ساعة' : 'منذ $hoursس $minutesد';
}

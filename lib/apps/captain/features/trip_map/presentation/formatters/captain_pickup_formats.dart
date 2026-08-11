class CaptainPickupFormats {
  const CaptainPickupFormats._();

  static String? distance(double? meters) {
    if (meters == null) return null;
    if (meters < 950) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  static String countdown(DateTime? target, {required DateTime now}) {
    if (target == null) return '—';
    final left = target.difference(now);
    if (left.inSeconds <= 60) return 'الآن';
    if (left.inMinutes < 60) return '${left.inMinutes} دقيقة';
    final hours = left.inHours;
    final minutes = left.inMinutes.remainder(60);
    return minutes == 0 ? '$hours ساعة' : '$hoursس $minutesد';
  }
}

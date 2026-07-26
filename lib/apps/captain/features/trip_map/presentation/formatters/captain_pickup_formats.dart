/// Distance and arrival wording for the pickup panel, in one place so the map
/// and the panel read a number the same way.
class CaptainPickupFormats {
  const CaptainPickupFormats._();

  /// A road distance in Arabic units: meters under a kilometre, one-decimal
  /// kilometres above it. Null renders as a dash by the caller.
  static String? distance(double? meters) {
    if (meters == null) return null;
    if (meters < 950) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  /// A countdown to [target] read against [now]. Anything due, or within the
  /// next minute, is "الآن" — a captain pulling up to a stop doesn't want
  /// "0 دقيقة".
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

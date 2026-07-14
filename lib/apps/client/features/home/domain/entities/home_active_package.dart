/// The subscription the rider is currently riding on. Home only shows packages
/// when one of these exists — it never advertises plans the rider has not
/// bought.
class HomeActivePackageData {
  const HomeActivePackageData({
    required this.title,
    required this.routeLabel,
    this.startDate,
    this.endDate,
  });

  final String title;

  /// Route the package is bound to; empty when it is not route-bound.
  final String routeLabel;

  final DateTime? startDate;
  final DateTime? endDate;

  /// Whole days left before the package lapses; 0 once it has.
  int get remainingDays {
    final end = endDate;
    if (end == null) return 0;
    final now = DateTime.now();
    final days = DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return days < 0 ? 0 : days;
  }

  /// Length of the subscription window; 0 when the dashboard left dates unset.
  int get totalDays {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return 0;
    final days = end.difference(start).inDays;
    return days < 0 ? 0 : days;
  }

  /// Share of the window still unused, for the progress bar.
  double get remainingRatio {
    if (totalDays == 0) return 0;
    return (remainingDays / totalDays).clamp(0.0, 1.0);
  }
}

/// The subscription the rider currently holds, with the usage detail Home's
/// lighter `HomeActivePackageData` does not carry — trip counts and the row's
/// own id, for a dedicated "my subscription" screen.
class MySubscription {
  const MySubscription({
    required this.id,
    required this.packageName,
    required this.routeName,
    required this.status,
    required this.tripsTotal,
    required this.tripsUsed,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String packageName;
  final String routeName;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Rides the package grants; 0 means the Dashboard left it unlimited.
  final int tripsTotal;

  /// Rides an admin has marked used against this subscription so far.
  final int tripsUsed;

  bool get hasTripLimit => tripsTotal > 0;

  int get tripsRemaining =>
      hasTripLimit ? (tripsTotal - tripsUsed).clamp(0, tripsTotal) : 0;

  /// Share of the trip allowance already used, for the progress bar.
  double get tripsRatio =>
      hasTripLimit ? (tripsUsed / tripsTotal).clamp(0.0, 1.0) : 0;

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

  /// Length of the subscription window; 0 when either date is unset.
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

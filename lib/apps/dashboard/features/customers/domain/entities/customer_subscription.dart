/// One subscription this customer holds with this office.
///
/// Read from `subscriptions` — the table الاشتراكات sells and reports. The
/// booking funnel's `transport_subscriptions` is a different table for a
/// different job and is not listed here; see CLIENTS_DATA_MODEL.md §4.
class CustomerSubscription {
  final String id;
  final String packageName;
  final String? routeName;

  /// `active` | `expired` | `cancelled`, the database's own vocabulary.
  final String status;

  final DateTime? startDate;
  final DateTime? endDate;

  final int tripsCount;
  final int tripsUsed;
  final int tripsRemaining;

  /// Percent used, already rounded server-side. **Null when [tripsCount] is
  /// zero**, which is a real value in this data: three seeded rows carry it.
  /// A null here means "cannot be computed", and the screen must omit the bar
  /// rather than draw an empty one that reads as 0% used.
  final double? usagePercent;

  final double totalPrice;
  final double paidAmount;
  final double remainingAmount;
  final int renewalsCount;
  final String? paymentMethod;
  final String? paymentReviewStatus;
  final DateTime createdAt;

  /// `status == 'active'` **and** not past its end date.
  ///
  /// The status column alone goes stale: expiry is swept by
  /// `office_expire_overdue_subscriptions()`, which only runs when the
  /// الاشتراكات module calls it. This module is a read surface and does not
  /// mutate on read, so it corrects the staleness in the predicate instead.
  final bool isCurrent;

  const CustomerSubscription({
    required this.id,
    required this.packageName,
    required this.status,
    required this.createdAt,
    this.routeName,
    this.startDate,
    this.endDate,
    this.tripsCount = 0,
    this.tripsUsed = 0,
    this.tripsRemaining = 0,
    this.usagePercent,
    this.totalPrice = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.renewalsCount = 0,
    this.paymentMethod,
    this.paymentReviewStatus,
    this.isCurrent = false,
  });

  /// Usage as a 0–1 fraction for a progress bar, or null when it cannot be
  /// computed. Clamped: `trips_used` can exceed `trips_count` on a package that
  /// was consumed past its allowance, and a bar wider than its track is a
  /// rendering bug rather than a finding.
  double? get usageFraction {
    final percent = usagePercent;
    if (percent == null) return null;
    return (percent / 100).clamp(0.0, 1.0);
  }

  /// Days until expiry, negative once past. Null when the subscription carries
  /// no end date.
  int? daysRemaining(DateTime today) {
    final end = endDate;
    if (end == null) return null;
    return DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
  }
}

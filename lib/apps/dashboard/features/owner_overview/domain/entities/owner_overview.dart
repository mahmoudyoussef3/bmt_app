class OwnerRevenuePoint {
  final DateTime date;
  final double amount;

  const OwnerRevenuePoint({required this.date, required this.amount});
}

class OwnerPlanStat {
  final String plan;
  final int clients;
  final double revenue;

  const OwnerPlanStat({
    required this.plan,
    required this.clients,
    required this.revenue,
  });
}

/// Owner-level business overview, aggregated entirely from real tables
/// (`subscriptions`, `operation_bookings`, `revenue_daily_view`). This is a
/// single-tenant revenue view — not multi-tenant SaaS, which has no backend.
class OwnerOverview {
  final double subscriptionsRevenue;
  final double bookingsRevenueTotal;
  final double bookingsRevenueToday;
  final double bookingsRevenueMonth;
  final int activeClients;
  final int expiredClients;
  final int cancelledClients;
  final int activeSubscriptions;
  final int renewalsTotal;
  final List<OwnerRevenuePoint> revenueTrend;
  final List<OwnerPlanStat> byPlan;

  const OwnerOverview({
    required this.subscriptionsRevenue,
    required this.bookingsRevenueTotal,
    required this.bookingsRevenueToday,
    required this.bookingsRevenueMonth,
    required this.activeClients,
    required this.expiredClients,
    required this.cancelledClients,
    required this.activeSubscriptions,
    required this.renewalsTotal,
    required this.revenueTrend,
    required this.byPlan,
  });

  double get totalRevenue => subscriptionsRevenue + bookingsRevenueTotal;
}

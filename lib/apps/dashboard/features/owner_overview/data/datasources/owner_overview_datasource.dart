import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/owner_overview.dart';

/// Aggregates the owner overview from real tables only.
class OwnerOverviewDatasource {
  final SupabaseClient _client;

  const OwnerOverviewDatasource(this._client);

  Future<OwnerOverview> getOverview() async {
    final subs = await _client
        .from('subscriptions')
        .select('status, total_price, total_revenue, renewals_count, package_name');
    final bookings = await _client
        .from('operation_bookings')
        .select('payment_amount, status, created_at');
    final trendRows = await _client
        .from('revenue_daily_view')
        .select('report_date, total_bookings_revenue')
        .order('report_date', ascending: true)
        .limit(60);

    return OwnerOverview(
      subscriptionsRevenue: _subscriptionsRevenue(subs as List),
      bookingsRevenueTotal: _bookingsRevenue(bookings as List, _Range.all),
      bookingsRevenueToday: _bookingsRevenue(bookings, _Range.today),
      bookingsRevenueMonth: _bookingsRevenue(bookings, _Range.month),
      activeClients: _countStatus(subs, 'active'),
      expiredClients: _countStatus(subs, 'expired'),
      cancelledClients: _countStatus(subs, 'cancelled'),
      activeSubscriptions: _countStatus(subs, 'active'),
      renewalsTotal: _renewals(subs),
      revenueTrend: _trend(trendRows as List),
      byPlan: _byPlan(subs),
    );
  }

  double _subscriptionsRevenue(List rows) {
    var total = 0.0;
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final rev = double.tryParse(r['total_revenue']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(r['total_price']?.toString() ?? '0') ?? 0;
      total += rev > 0 ? rev : price;
    }
    return total;
  }

  double _bookingsRevenue(List rows, _Range range) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = now.subtract(const Duration(days: 30));
    var total = 0.0;
    for (final r in rows.cast<Map<String, dynamic>>()) {
      if (r['status'] == 'rejected' || r['status'] == 'cancelled') continue;
      final amount = double.tryParse(r['payment_amount']?.toString() ?? '0') ?? 0;
      final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
      switch (range) {
        case _Range.all:
          total += amount;
        case _Range.today:
          if (date != null && !date.isBefore(todayStart)) total += amount;
        case _Range.month:
          if (date != null && date.isAfter(monthStart)) total += amount;
      }
    }
    return total;
  }

  int _countStatus(List rows, String status) =>
      rows.where((r) => (r as Map)['status'] == status).length;

  int _renewals(List rows) {
    var total = 0;
    for (final r in rows.cast<Map<String, dynamic>>()) {
      total += int.tryParse(r['renewals_count']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  List<OwnerRevenuePoint> _trend(List rows) {
    return rows.cast<Map<String, dynamic>>().map((r) {
      return OwnerRevenuePoint(
        date: DateTime.tryParse(r['report_date']?.toString() ?? '') ??
            DateTime.now(),
        amount:
            double.tryParse(r['total_bookings_revenue']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  List<OwnerPlanStat> _byPlan(List rows) {
    final clients = <String, int>{};
    final revenue = <String, double>{};
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final plan = r['package_name']?.toString() ?? 'باقة';
      final price = double.tryParse(r['total_price']?.toString() ?? '0') ?? 0;
      clients[plan] = (clients[plan] ?? 0) + 1;
      revenue[plan] = (revenue[plan] ?? 0) + price;
    }
    final stats = clients.keys
        .map((p) => OwnerPlanStat(
              plan: p,
              clients: clients[p] ?? 0,
              revenue: revenue[p] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.clients.compareTo(a.clients));
    return stats;
  }
}

enum _Range { all, today, month }

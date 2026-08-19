import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/report_entities.dart';
import 'reports_datasource.dart';

/// The reports module's reads.
///
/// Two different kinds of source sit behind the seven reports, and the
/// difference decides what each one can be filtered by:
///
///  * **The licensed views** — `revenue_daily_view`,
///    `drivers_performance_view`, `vehicles_efficiency_view` and
///    `complaints_summary_view`. These are office-scoped in their own bodies
///    and, since `20260808090000_licensing_enforcement_completion`, three of
///    them carry `office_licensed('reports')` as a real server-side read gate.
///    They are lifetime roll-ups with no date dimension, so the reports built
///    on them declare `usesDateRange == false` rather than showing a date range
///    they quietly ignore.
///
///  * **The base tables** — `operation_trips`, `operation_bookings`,
///    `subscriptions`. These carry dates and dimensions, so the reports built
///    on them are genuinely period-bounded and genuinely filterable. Three of
///    them (trips, bookings, subscriptions) used to return a single KPI reading
///    "قيد التطوير الفعلي"; they return real rows now.
///
/// Trip revenue is summed from the trip's own approved bookings, never from
/// `operation_trips.revenue` — that column is not maintained.
class SupabaseReportsDatasource implements ReportsDatasource {
  final SupabaseClient _client;

  SupabaseReportsDatasource(this._client);

  /// Bookings whose money counts as earned. Mirrors the finance module's rule
  /// so a route's revenue reads the same in both places.
  static const _earnedBookingStatuses = {'approved', 'confirmed', 'completed'};

  @override
  Future<ReportData> getReportData(ReportType type, ReportFilter filter) async {
    return switch (type) {
      ReportType.revenue => _revenueReport(filter),
      ReportType.trips => _tripsReport(filter),
      ReportType.bookings => _bookingsReport(filter),
      ReportType.drivers => _driversReport(filter),
      ReportType.vehicles => _vehiclesReport(filter),
      ReportType.subscriptions => _subscriptionsReport(filter),
      ReportType.complaints => _complaintsReport(),
    };
  }

  // ── Period helpers ────────────────────────────────────────────────────────

  String _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).toUtc().toIso8601String();

  String _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59).toUtc().toIso8601String();

  /// `trip_date` is a DATE column, so it is bounded with plain calendar days
  /// rather than the UTC instants used for `created_at` timestamps — shifting a
  /// date into UTC can move it a day and silently drop the edges of the range.
  String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Revenue ───────────────────────────────────────────────────────────────

  Future<ReportData> _revenueReport(ReportFilter filter) async {
    final response = await _client
        .from('revenue_daily_view')
        .select()
        .gte('report_date', _day(filter.startDate))
        .lte('report_date', _day(filter.endDate))
        .order('report_date', ascending: true);

    final rows = <RevenueReportRow>[];
    final trends = <MapEntry<String, double>>[];
    var total = 0.0;
    var bookings = 0;

    for (final r in (response as List).cast<Map<String, dynamic>>()) {
      final revenue = _toDouble(r['total_bookings_revenue']);
      final count = _toInt(r['total_bookings']);
      final date = DateTime.tryParse('${r['report_date']}');
      if (date == null) continue;

      total += revenue;
      bookings += count;
      rows.add(
        RevenueReportRow(
          date: date.toLocal(),
          totalRevenue: revenue,
          bookingsRevenue: revenue,
          subscriptionsRevenue: 0,
          refundsCount: 0,
          netRevenue: revenue,
        ),
      );
      trends.add(MapEntry(_day(date), revenue));
    }

    final days = rows.length;
    return ReportData(
      kpis: {
        'إيراد الحجوزات': _money(total),
        'عدد الحجوزات': '$bookings حجز',
        'متوسط قيمة الحجز': _money(bookings == 0 ? 0 : total / bookings),
        'متوسط الإيراد اليومي': _money(days == 0 ? 0 : total / days),
      },
      rows: rows,
      trends: trends,
      occupancyTrends: await _occupancyByRoute(filter),
    );
  }

  // ── Trips ─────────────────────────────────────────────────────────────────

  Future<ReportData> _tripsReport(ReportFilter filter) async {
    final trips = await _fetchTrips(filter);
    final revenueByTrip = await _revenueByTrip(
      trips.map((t) => '${t['id']}').toList(),
    );

    final rows = <TripReportRow>[];
    final byRoute = <String, double>{};
    var completed = 0;
    var passengers = 0;
    var capacity = 0;
    var revenue = 0.0;

    for (final t in trips) {
      final id = '${t['id']}';
      final seats = (t['seats'] as List?) ?? const [];
      final booked = seats
          .where((s) => (s as Map)['state'] != 'available')
          .length;
      final seatCount = _toInt(t['capacity']);
      final status = '${t['status']}';
      final tripRevenue = revenueByTrip[id] ?? 0;

      if (status == 'completed') completed++;
      passengers += booked;
      capacity += seatCount;
      revenue += tripRevenue;

      final routeName = _nested(t, 'route', 'name') ?? 'بدون مسار';
      byRoute[routeName] = (byRoute[routeName] ?? 0) + tripRevenue;

      rows.add(
        TripReportRow(
          tripId: '${t['trip_code'] ?? id}',
          routeCode: routeName,
          driverName: _nested(t, 'driver', 'full_name') ?? 'غير محدد',
          vehiclePlate: _nested(t, 'vehicle', 'plate_number') ?? 'غير محددة',
          passengerCount: booked,
          occupancyRate: seatCount == 0 ? 0 : booked / seatCount,
          revenue: tripRevenue,
          date:
              DateTime.tryParse('${t['trip_date']}')?.toLocal() ??
              DateTime.now(),
          status: _tripStatusLabel(status),
        ),
      );
    }

    final trends = <MapEntry<String, double>>[
      for (final entry
          in (byRoute.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(7))
        MapEntry(entry.key, entry.value),
    ];

    return ReportData(
      kpis: {
        'عدد الرحلات': '${rows.length} رحلة',
        'الرحلات المكتملة': '$completed رحلة',
        'نسبة الإشغال': _percent(capacity == 0 ? 0 : passengers / capacity),
        'إيراد الرحلات': _money(revenue),
      },
      rows: rows,
      trends: trends,
      occupancyTrends: await _occupancyByRoute(filter),
    );
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  Future<ReportData> _bookingsReport(ReportFilter filter) async {
    final response = await _client
        .from('operation_bookings')
        .select('''
          id, booking_number, passenger_name, status, payment_amount,
          payment_method, created_at,
          trip:operation_trips(trip_code, route:operation_routes(name))
        ''')
        .gte('created_at', _startOfDay(filter.startDate))
        .lte('created_at', _endOfDay(filter.endDate))
        .order('created_at', ascending: false);

    final rows = <BookingReportRow>[];
    final byMethod = <String, double>{};
    var earned = 0.0;
    var earnedCount = 0;
    var rejected = 0;

    for (final b in (response as List).cast<Map<String, dynamic>>()) {
      final routeName =
          _nested(_nestedMap(b, 'trip'), 'route', 'name') ?? 'بدون مسار';
      if (!_matches(filter.routeCode, routeName)) continue;

      final status = '${b['status']}';
      final amount = _toDouble(b['payment_amount']);
      final method = '${b['payment_method'] ?? 'غير محدد'}';

      if (_earnedBookingStatuses.contains(status)) {
        earned += amount;
        earnedCount++;
        byMethod[method] = (byMethod[method] ?? 0) + amount;
      }
      if (status == 'rejected' || status == 'cancelled') rejected++;

      rows.add(
        BookingReportRow(
          bookingId: '${b['booking_number'] ?? b['id']}',
          clientName: '${b['passenger_name'] ?? '—'}',
          tripId: '${_nestedMap(b, 'trip')?['trip_code'] ?? '—'}',
          amount: amount,
          paymentMethod: method,
          status: _bookingStatusLabel(status),
          date:
              DateTime.tryParse('${b['created_at']}')?.toLocal() ??
              DateTime.now(),
        ),
      );
    }

    return ReportData(
      kpis: {
        'عدد الحجوزات': '${rows.length} حجز',
        'حجوزات محصّلة': '$earnedCount حجز',
        'حجوزات مرفوضة أو ملغاة': '$rejected حجز',
        'قيمة المحصّل': _money(earned),
      },
      rows: rows,
      trends: byMethod.entries.toList(),
    );
  }

  // ── Drivers / vehicles / complaints — the licensed views ──────────────────

  Future<ReportData> _driversReport(ReportFilter filter) async {
    final response = await _client.from('drivers_performance_view').select();

    final rows = <DriverReportRow>[];
    var active = 0;
    var trips = 0;
    var revenue = 0.0;

    for (final r in (response as List).cast<Map<String, dynamic>>()) {
      final name = '${r['name'] ?? '—'}';
      if (!_matches(filter.driverName, name)) continue;

      final status = '${r['status']}';
      final completed = _toInt(r['completed_trips']);
      final driverRevenue = _toDouble(r['total_revenue']);

      if (status == 'active') active++;
      trips += completed;
      revenue += driverRevenue;

      rows.add(
        DriverReportRow(
          driverId: '${r['driver_id']}',
          name: name,
          completedTrips: completed,
          totalRevenue: driverRevenue,
          status: status == 'active' ? 'نشط' : 'غير نشط',
        ),
      );
    }

    rows.sort((a, b) => b.completedTrips.compareTo(a.completedTrips));

    return ReportData(
      kpis: {
        'عدد السائقين': '${rows.length} سائق',
        'السائقون النشطون': '$active سائق',
        'إجمالي الرحلات المنجزة': '$trips رحلة',
        'الإيراد المنسوب للسائقين': _money(revenue),
      },
      rows: rows,
      trends: [
        for (final row in rows.take(7))
          MapEntry(row.name, row.completedTrips.toDouble()),
      ],
    );
  }

  Future<ReportData> _vehiclesReport(ReportFilter filter) async {
    final response = await _client.from('vehicles_efficiency_view').select();

    final rows = <VehicleReportRow>[];
    var active = 0;
    var ready = 0;
    var occupancySum = 0.0;

    for (final r in (response as List).cast<Map<String, dynamic>>()) {
      final plate = '${r['plate_number'] ?? '—'}';
      if (!_matches(filter.vehiclePlate, plate)) continue;

      final status = '${r['status']}';
      final maintenance = '${r['maintenance_status']}';

      // The view reports occupancy as a ratio in some rows and a percentage in
      // others depending on how the trip recorded it; normalise to 0–1 here so
      // the column and the KPI cannot disagree.
      final raw = _toDouble(r['avg_occupancy_rate']);
      final occupancy = raw > 1 ? raw / 100 : raw;

      if (status == 'active') active++;
      if (maintenance == 'جاهزة') ready++;
      occupancySum += occupancy;

      rows.add(
        VehicleReportRow(
          vehicleId: '${r['vehicle_id']}',
          plateNumber: plate,
          model: '${r['model'] ?? '—'}',
          completedTrips: _toInt(r['completed_trips']),
          avgOccupancyRate: occupancy,
          maintenanceStatus: maintenance,
          status: status == 'active' ? 'في الخدمة' : 'متوقفة',
        ),
      );
    }

    rows.sort((a, b) => b.completedTrips.compareTo(a.completedTrips));

    return ReportData(
      kpis: {
        'إجمالي المركبات': '${rows.length} مركبة',
        'مركبات جاهزة للخدمة': '$ready مركبة',
        'مركبات في الخدمة': '$active مركبة',
        'متوسط الإشغال': _percent(
          rows.isEmpty ? 0 : occupancySum / rows.length,
        ),
      },
      rows: rows,
      trends: [
        for (final row in rows.take(7))
          MapEntry(row.plateNumber, row.completedTrips.toDouble()),
      ],
    );
  }

  Future<ReportData> _complaintsReport() async {
    final response = await _client.from('complaints_summary_view').select();

    final rows = <ComplaintReportRow>[];
    var total = 0;
    var resolved = 0;
    var pending = 0;

    for (final r in (response as List).cast<Map<String, dynamic>>()) {
      final all = _toInt(r['total_complaints']);
      final done = _toInt(r['resolved_complaints']);
      final open = _toInt(r['pending_complaints']);

      total += all;
      resolved += done;
      pending += open;

      rows.add(
        ComplaintReportRow(
          category: '${r['category'] ?? 'غير مصنّفة'}',
          totalComplaints: all,
          resolvedComplaints: done,
          pendingComplaints: open,
        ),
      );
    }

    return ReportData(
      kpis: {
        'إجمالي الشكاوى': '$total شكوى',
        'تم حلها': '$resolved شكوى',
        'قيد المراجعة': '$pending شكوى',
        'نسبة الحل': _percent(total == 0 ? 0 : resolved / total),
      },
      rows: rows,
      trends: [
        for (final row in rows)
          MapEntry(row.category, row.totalComplaints.toDouble()),
      ],
    );
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  Future<ReportData> _subscriptionsReport(ReportFilter filter) async {
    final response = await _client
        .from('subscriptions')
        .select('package_name, status, total_price, renewals_count');

    final byPackage = <String, SubscriptionReportRow>{};
    var active = 0;
    var expired = 0;
    var revenue = 0.0;
    var renewals = 0;

    for (final s in (response as List).cast<Map<String, dynamic>>()) {
      final package = '${s['package_name'] ?? 'بدون باقة'}';
      if (!_matches(filter.packageName, package)) continue;

      final status = '${s['status']}';
      final price = _toDouble(s['total_price']);
      final renewed = _toInt(s['renewals_count']);

      final current =
          byPackage[package] ??
          SubscriptionReportRow(
            packageName: package,
            activeUsers: 0,
            expiredUsers: 0,
            totalRevenue: 0,
            renewalsCount: 0,
          );

      byPackage[package] = SubscriptionReportRow(
        packageName: package,
        activeUsers: current.activeUsers + (status == 'active' ? 1 : 0),
        expiredUsers: current.expiredUsers + (status == 'expired' ? 1 : 0),
        totalRevenue: current.totalRevenue + price,
        renewalsCount: current.renewalsCount + renewed,
      );

      if (status == 'active') active++;
      if (status == 'expired') expired++;
      revenue += price;
      renewals += renewed;
    }

    final rows = byPackage.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return ReportData(
      kpis: {
        'عدد الباقات المُباعة': '${rows.length} باقة',
        'اشتراكات نشطة': '$active اشتراك',
        'اشتراكات منتهية': '$expired اشتراك',
        'إيراد الاشتراكات': _money(revenue),
      },
      rows: rows,
      trends: [
        for (final row in rows.take(7))
          MapEntry(row.packageName, row.totalRevenue),
      ],
      occupancyTrends: [
        if (renewals > 0) MapEntry('تجديدات', renewals.toDouble()),
      ],
    );
  }

  // ── Shared reads ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchTrips(ReportFilter filter) async {
    final response = await _client
        .from('operation_trips')
        .select('''
          id, trip_code, trip_date, status, capacity,
          route:operation_routes(name),
          driver:drivers(full_name),
          vehicle:vehicles(plate_number),
          seats:trip_seats(state)
        ''')
        .gte('trip_date', _day(filter.startDate))
        .lte('trip_date', _day(filter.endDate))
        .order('trip_date', ascending: false);

    return (response as List).cast<Map<String, dynamic>>().where((t) {
      return _matches(filter.routeCode, _nested(t, 'route', 'name')) &&
          _matches(filter.driverName, _nested(t, 'driver', 'full_name')) &&
          _matches(filter.vehiclePlate, _nested(t, 'vehicle', 'plate_number'));
    }).toList();
  }

  /// Earned revenue per trip, summed from that trip's own bookings.
  ///
  /// `operation_trips.revenue` exists but is not maintained by any writer, so
  /// reading it would report zero for every trip.
  Future<Map<String, double>> _revenueByTrip(List<String> tripIds) async {
    if (tripIds.isEmpty) return const {};

    final response = await _client
        .from('operation_bookings')
        .select('trip_id, payment_amount, status')
        .inFilter('trip_id', tripIds);

    final byTrip = <String, double>{};
    for (final b in (response as List).cast<Map<String, dynamic>>()) {
      if (!_earnedBookingStatuses.contains('${b['status']}')) continue;
      final id = '${b['trip_id']}';
      byTrip[id] = (byTrip[id] ?? 0) + _toDouble(b['payment_amount']);
    }
    return byTrip;
  }

  /// Mean occupancy per route over the selected period.
  ///
  /// Previously capped at ten arbitrary trips, which made the chart a sample of
  /// whatever the database happened to return first rather than a measurement.
  Future<List<MapEntry<String, double>>> _occupancyByRoute(
    ReportFilter filter,
  ) async {
    try {
      final trips = await _fetchTrips(filter);
      final byRoute = <String, List<double>>{};

      for (final t in trips) {
        final capacity = _toInt(t['capacity']);
        if (capacity == 0) continue;
        final seats = (t['seats'] as List?) ?? const [];
        final booked = seats
            .where((s) => (s as Map)['state'] != 'available')
            .length;
        final route = _nested(t, 'route', 'name') ?? 'بدون مسار';
        byRoute.putIfAbsent(route, () => []).add(booked / capacity * 100);
      }

      return byRoute.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return MapEntry(
          e.key.length > 12 ? '${e.key.substring(0, 12)}…' : e.key,
          avg,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Filter option lists ───────────────────────────────────────────────────

  @override
  Future<List<String>> getAvailableRoutes() async {
    final response = await _client.from('operation_routes').select('name');
    return _distinct(response, 'name');
  }

  @override
  Future<List<String>> getAvailableDrivers() async {
    final response = await _client.from('drivers').select('full_name');
    return _distinct(response, 'full_name');
  }

  @override
  Future<List<String>> getAvailableVehicles() async {
    final response = await _client.from('vehicles').select('plate_number');
    return _distinct(response, 'plate_number');
  }

  @override
  Future<List<String>> getAvailablePackages() async {
    final response = await _client.from('subscriptions').select('package_name');
    return _distinct(response, 'package_name');
  }

  /// The dropdowns used to repeat a name once per row — one entry per
  /// subscription sold, not one per package.
  List<String> _distinct(dynamic response, String column) {
    final values = <String>{};
    for (final row in (response as List).cast<Map<String, dynamic>>()) {
      final value = '${row[column] ?? ''}'.trim();
      if (value.isNotEmpty) values.add(value);
    }
    return values.toList()..sort();
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  static bool _matches(String? selected, String? value) =>
      selected == null || selected.isEmpty || selected == value;

  static Map<String, dynamic>? _nestedMap(Map<String, dynamic>? row, String k) {
    final value = row?[k];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static String? _nested(Map<String, dynamic>? row, String key, String field) {
    final value = _nestedMap(row, key)?[field];
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static double _toDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int _toInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static String _money(double value) => '${value.toStringAsFixed(0)} ج.م';

  static String _percent(double ratio) =>
      '${(ratio * 100).toStringAsFixed(0)}%';

  static String _tripStatusLabel(String status) => switch (status) {
    'completed' => 'مكتملة',
    'in_progress' => 'جارية',
    'boarding' => 'صعود',
    'cancelled' => 'ملغاة',
    'scheduled' || 'open_for_booking' => 'مجدولة',
    _ => status,
  };

  static String _bookingStatusLabel(String status) => switch (status) {
    'approved' || 'confirmed' => 'مؤكدة',
    'completed' => 'مكتملة',
    'reserved' || 'pending' => 'قيد المراجعة',
    'rejected' => 'مرفوضة',
    'cancelled' => 'ملغاة',
    _ => status,
  };
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/report_entities.dart';
import 'reports_datasource.dart';

class SupabaseReportsDatasource implements ReportsDatasource {
  final SupabaseClient _client;

  SupabaseReportsDatasource(this._client);

  @override
  Future<ReportData> getReportData(ReportType type, ReportFilter filter) async {
    final startOfDay = DateTime(filter.startDate.year, filter.startDate.month, filter.startDate.day).toUtc().toIso8601String();
    final endOfDay = DateTime(filter.endDate.year, filter.endDate.month, filter.endDate.day, 23, 59, 59).toUtc().toIso8601String();

    final kpis = <String, String>{};
    final List<dynamic> rows = [];
    final List<MapEntry<String, double>> trends = [];

    switch (type) {
      case ReportType.revenue:
        final response = await _client
            .from('revenue_daily_view')
            .select()
            .gte('report_date', startOfDay)
            .lte('report_date', endOfDay);

        double totalNet = 0;
        double totalBkgRev = 0;
        int totalRefundsCount = 0; // Stub since refunds aren't tracked yet
        double totalSubRev = 0; // Stub since subscriptions aren't tracked yet

        for (var r in response) {
          final rev = double.tryParse(r['total_bookings_revenue'].toString()) ?? 0.0;
          totalBkgRev += rev;
          totalNet += rev;
          
          rows.add(RevenueReportRow(
            date: DateTime.parse(r['report_date'].toString()).toLocal(),
            totalRevenue: rev,
            bookingsRevenue: rev,
            subscriptionsRevenue: 0,
            refundsCount: 0,
            netRevenue: rev,
          ));
          
          trends.add(MapEntry(r['report_date'].toString(), rev));
        }

        kpis['صافي الإيرادات'] = '${totalNet.toStringAsFixed(0)} ج.م';
        kpis['إيرادات حجز الرحلات'] = '${totalBkgRev.toStringAsFixed(0)} ج.م';
        kpis['إيرادات الاشتراكات'] = '${totalSubRev.toStringAsFixed(0)} ج.م';
        kpis['عدد عمليات الاسترداد'] = '$totalRefundsCount طلب مسترد';
        break;

      case ReportType.drivers:
        final response = await _client.from('drivers_performance_view').select();
        
        int activeDrivers = 0;
        int sumTrips = 0;
        double sumHours = 0;
        double totalRating = 0;
        int ratedDrivers = 0;

        for (var r in response) {
          final status = r['status'].toString();
          if (status == 'active') activeDrivers++;
          
          final trips = int.tryParse(r['completed_trips'].toString()) ?? 0;
          sumTrips += trips;
          
          final rev = double.tryParse(r['total_revenue'].toString()) ?? 0.0;
          final hours = double.tryParse(r['total_working_hours'].toString()) ?? 0.0;
          sumHours += hours;
          
          final rating = double.tryParse(r['rating'].toString()) ?? 0.0;
          if (rating > 0) {
            totalRating += rating;
            ratedDrivers++;
          }

          rows.add(DriverReportRow(
            driverId: r['driver_id'].toString(),
            name: r['name'].toString(),
            completedTrips: trips,
            totalWorkingHours: hours,
            rating: rating,
            totalRevenue: rev,
            status: status == 'active' ? 'نشط' : 'غير نشط',
          ));
          
          if (trends.length < 7) {
            trends.add(MapEntry(r['name'].toString(), trips.toDouble()));
          }
        }

        final avgRating = ratedDrivers > 0 ? totalRating / ratedDrivers : 0.0;

        kpis['عدد السائقين'] = '${rows.length} سائق';
        kpis['السائقين النشطين حالياً'] = '$activeDrivers سائق';
        kpis['متوسط تقييم الأداء'] = '${avgRating.toStringAsFixed(2)} ★';
        kpis['إجمالي الرحلات المنجزة'] = '$sumTrips رحلة';
        kpis['إجمالي ساعات العمل'] = '${sumHours.toStringAsFixed(0)} ساعة';
        break;

      case ReportType.vehicles:
        final response = await _client.from('vehicles_efficiency_view').select();
        
        int activeVehicles = 0;
        int readyVehicles = 0;
        double sumFuel = 0;

        for (var r in response) {
          final status = r['status'].toString();
          if (status == 'active') activeVehicles++;
          
          final maintenance = r['maintenance_status'].toString();
          if (maintenance == 'جاهزة') readyVehicles++;
          
          final trips = int.tryParse(r['completed_trips'].toString()) ?? 0;
          final fuel = double.tryParse(r['fuel_consumption'].toString()) ?? 0.0;
          sumFuel += fuel;

          rows.add(VehicleReportRow(
            vehicleId: r['vehicle_id'].toString(),
            plateNumber: r['plate_number'].toString(),
            model: r['model'].toString(),
            completedTrips: trips,
            fuelConsumption: fuel,
            maintenanceStatus: maintenance,
            status: status == 'active' ? 'في الخدمة' : 'متوقفة',
          ));

          if (trends.length < 7) {
            trends.add(MapEntry(r['plate_number'].toString(), trips.toDouble()));
          }
        }

        final avgFuel = rows.isNotEmpty ? sumFuel / rows.length : 0.0;

        kpis['إجمالي أسطول المركبات'] = '${rows.length} مركبة';
        kpis['مركبات جاهزة للخدمة'] = '$readyVehicles مركبة';
        kpis['المركبات قيد التشغيل'] = '$activeVehicles مركبة';
        kpis['متوسط استهلاك الوقود'] = '${avgFuel.toStringAsFixed(1)} لتر/100كم';
        break;

      case ReportType.complaints:
        final response = await _client.from('complaints_summary_view').select();
        
        int totalComplaints = 0;
        int resolved = 0;
        int pending = 0;
        double avgTime = 0.0; // Stub

        for (var r in response) {
          final total = int.tryParse(r['total_complaints'].toString()) ?? 0;
          final res = int.tryParse(r['resolved_complaints'].toString()) ?? 0;
          final pend = int.tryParse(r['pending_complaints'].toString()) ?? 0;
          final time = double.tryParse(r['avg_resolution_time'].toString()) ?? 0.0;
          
          totalComplaints += total;
          resolved += res;
          pending += pend;
          avgTime = time; // Taking the stub value

          rows.add(ComplaintReportRow(
            category: r['category'].toString(),
            totalComplaints: total,
            resolvedComplaints: res,
            avgResolutionTime: time,
            pendingComplaints: pend,
          ));

          trends.add(MapEntry(r['category'].toString(), total.toDouble()));
        }

        kpis['إجمالي الشكاوى الواردة'] = '$totalComplaints شكوى';
        kpis['الشكاوى التي تم حلها'] = '$resolved شكوى';
        kpis['شكاوى قيد المراجعة والحل'] = '$pending شكوى معلقة';
        kpis['متوسط سرعة الاستجابة والحل'] = '${avgTime.toStringAsFixed(1)} ساعة';
        break;

      case ReportType.trips:
      case ReportType.bookings:
      case ReportType.subscriptions:
        // Stub implementation for other types to prevent breaking the UI
        kpis['البيانات'] = 'قيد التطوير الفعلي';
        break;
    }

    return ReportData(kpis: kpis, rows: rows, trends: trends);
  }

  @override
  Future<List<String>> getAvailableRoutes() async {
    final response = await _client.from('operation_routes').select('name');
    return response.map((e) => e['name'].toString()).toList();
  }

  @override
  Future<List<String>> getAvailableDrivers() async {
    final response = await _client.from('drivers').select('full_name');
    return response.map((e) => e['full_name'].toString()).toList();
  }

  @override
  Future<List<String>> getAvailableVehicles() async {
    final response = await _client.from('vehicles').select('plate_number');
    return response.map((e) => e['plate_number'].toString()).toList();
  }

  @override
  Future<List<String>> getAvailablePackages() async {
    final response = await _client.from('subscriptions').select('package_name');
    return response.map((e) => e['package_name'].toString()).toList();
  }
}

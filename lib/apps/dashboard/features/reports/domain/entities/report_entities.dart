enum ReportType {
  trips('الرحلات'),
  bookings('الحجوزات'),
  revenue('الإيرادات'),
  drivers('السائقين'),
  vehicles('المركبات'),
  subscriptions('الاشتراكات'),
  complaints('الشكاوى');

  final String label;
  const ReportType(this.label);

  /// Which controls the filter bar may draw for this report.
  ///
  /// Every report used to draw all four dropdowns and a date range, and the
  /// datasource read **none** of them: an operator could pick a driver, watch
  /// the page reload, and get back exactly the same rows. A filter that cannot
  /// reach the query must not be offered, so each report declares what it can
  /// actually honour and the bar renders only that.
  Set<ReportFilterField> get supportedFilters => switch (this) {
    ReportType.trips => const {
      ReportFilterField.dateRange,
      ReportFilterField.route,
      ReportFilterField.driver,
      ReportFilterField.vehicle,
    },
    ReportType.bookings => const {
      ReportFilterField.dateRange,
      ReportFilterField.route,
    },
    ReportType.revenue => const {ReportFilterField.dateRange},
    ReportType.drivers => const {ReportFilterField.driver},
    ReportType.vehicles => const {ReportFilterField.vehicle},
    ReportType.subscriptions => const {ReportFilterField.package},
    ReportType.complaints => const {},
  };

  bool get usesDateRange =>
      supportedFilters.contains(ReportFilterField.dateRange);

  /// Said out loud on the page when the report cannot be bounded by a period,
  /// because a stale date range above lifetime totals reads as a date-filtered
  /// answer and is not one.
  String? get scopeNote => usesDateRange
      ? null
      : 'هذا التقرير يعرض الإجماليات التراكمية، ولا يتأثر بالفترة الزمنية المحددة.';
}

enum ReportFilterField { dateRange, route, driver, vehicle, package }

class ReportFilter {
  final DateTime startDate;
  final DateTime endDate;
  final String? routeCode;
  final String? driverName;
  final String? vehiclePlate;
  final String? packageName;

  const ReportFilter({
    required this.startDate,
    required this.endDate,
    this.routeCode,
    this.driverName,
    this.vehiclePlate,
    this.packageName,
  });

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? routeCode,
    bool clearRoute = false,
    String? driverName,
    bool clearDriver = false,
    String? vehiclePlate,
    bool clearVehicle = false,
    String? packageName,
    bool clearPackage = false,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      routeCode: clearRoute ? null : (routeCode ?? this.routeCode),
      driverName: clearDriver ? null : (driverName ?? this.driverName),
      vehiclePlate: clearVehicle ? null : (vehiclePlate ?? this.vehiclePlate),
      packageName: clearPackage ? null : (packageName ?? this.packageName),
    );
  }
}

class TripReportRow {
  final String tripId;
  final String routeCode;
  final String driverName;
  final String vehiclePlate;
  final int passengerCount;
  final double occupancyRate;
  final double revenue;
  final DateTime date;
  final String status;

  const TripReportRow({
    required this.tripId,
    required this.routeCode,
    required this.driverName,
    required this.vehiclePlate,
    required this.passengerCount,
    required this.occupancyRate,
    required this.revenue,
    required this.date,
    required this.status,
  });
}

class BookingReportRow {
  final String bookingId;
  final String clientName;
  final String tripId;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime date;

  const BookingReportRow({
    required this.bookingId,
    required this.clientName,
    required this.tripId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.date,
  });
}

class RevenueReportRow {
  final DateTime date;
  final double totalRevenue;
  final double bookingsRevenue;
  final double subscriptionsRevenue;
  final int refundsCount;
  final double netRevenue;

  const RevenueReportRow({
    required this.date,
    required this.totalRevenue,
    required this.bookingsRevenue,
    required this.subscriptionsRevenue,
    required this.refundsCount,
    required this.netRevenue,
  });
}

/// One row of `drivers_performance_view`.
///
/// `totalWorkingHours` and `rating` used to live here and were read out of the
/// view by name — but the view has never had either column, so both arrived as
/// null, parsed to 0, and were printed as "0 ساعة" and "0.0 ★" next to real
/// figures. Two fabricated columns are worse than two missing ones, so they are
/// gone until the view can answer them.
class DriverReportRow {
  final String driverId;
  final String name;
  final int completedTrips;
  final double totalRevenue;
  final String status;

  const DriverReportRow({
    required this.driverId,
    required this.name,
    required this.completedTrips,
    required this.totalRevenue,
    required this.status,
  });
}

/// One row of `vehicles_efficiency_view`.
///
/// Carried `fuelConsumption` for the same reason and with the same problem —
/// the view has no such column and never did. What it *does* have is
/// `avg_occupancy_rate`, which is a real operational number, so that is what
/// this now reports.
class VehicleReportRow {
  final String vehicleId;
  final String plateNumber;
  final String model;
  final int completedTrips;

  /// Mean seat occupancy across this vehicle's completed trips, 0–1.
  final double avgOccupancyRate;
  final String maintenanceStatus;
  final String status;

  const VehicleReportRow({
    required this.vehicleId,
    required this.plateNumber,
    required this.model,
    required this.completedTrips,
    required this.avgOccupancyRate,
    required this.maintenanceStatus,
    required this.status,
  });
}

class SubscriptionReportRow {
  final String packageName;
  final int activeUsers;
  final int expiredUsers;
  final double totalRevenue;
  final int renewalsCount;

  const SubscriptionReportRow({
    required this.packageName,
    required this.activeUsers,
    required this.expiredUsers,
    required this.totalRevenue,
    required this.renewalsCount,
  });
}

/// One row of `complaints_summary_view`.
///
/// `avgResolutionTime` is gone for the third time in this file's history of the
/// same mistake: the view groups by category and counts statuses, and has no
/// timing column to average.
class ComplaintReportRow {
  final String category;
  final int totalComplaints;
  final int resolvedComplaints;
  final int pendingComplaints;

  const ComplaintReportRow({
    required this.category,
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.pendingComplaints,
  });
}

class ReportData {
  /// The report these [rows] belong to.
  ///
  /// The rows are heterogeneous — a `TripReportRow` list for trips, a
  /// `BookingReportRow` list for bookings — so whoever renders them has to know
  /// which shape to cast to. Reading that from the *selected* report type is
  /// wrong: while a refetch is in flight the selection is already the new
  /// report and the data is still the old one, and the table crashed casting
  /// one to the other. The payload carries its own tag so the two can never
  /// disagree.
  final ReportType type;
  final Map<String, String> kpis;
  final List<dynamic> rows;
  final List<MapEntry<String, double>> trends;
  final List<MapEntry<String, double>> occupancyTrends;

  const ReportData({
    required this.type,
    required this.kpis,
    required this.rows,
    required this.trends,
    this.occupancyTrends = const [],
  });
}

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
}

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
  final double occupancyRate; // 0.0 to 1.0
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

class DriverReportRow {
  final String driverId;
  final String name;
  final int completedTrips;
  final double totalWorkingHours;
  final double rating;
  final double totalRevenue;
  final String status;

  const DriverReportRow({
    required this.driverId,
    required this.name,
    required this.completedTrips,
    required this.totalWorkingHours,
    required this.rating,
    required this.totalRevenue,
    required this.status,
  });
}

class VehicleReportRow {
  final String vehicleId;
  final String plateNumber;
  final String model;
  final int completedTrips;
  final double fuelConsumption; // L/100km
  final String maintenanceStatus;
  final String status;

  const VehicleReportRow({
    required this.vehicleId,
    required this.plateNumber,
    required this.model,
    required this.completedTrips,
    required this.fuelConsumption,
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

class ComplaintReportRow {
  final String category;
  final int totalComplaints;
  final int resolvedComplaints;
  final double avgResolutionTime; // hours
  final int pendingComplaints;

  const ComplaintReportRow({
    required this.category,
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.avgResolutionTime,
    required this.pendingComplaints,
  });
}

class ReportData {
  final Map<String, String> kpis;
  final List<dynamic> rows; // Will contain row types matching selection
  final List<MapEntry<String, double>> trends; // Trend data points for graphing

  const ReportData({
    required this.kpis,
    required this.rows,
    required this.trends,
  });
}

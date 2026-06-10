import '../../domain/entities/report_entities.dart';

class TripReportRowModel extends TripReportRow {
  const TripReportRowModel({
    required super.tripId,
    required super.routeCode,
    required super.driverName,
    required super.vehiclePlate,
    required super.passengerCount,
    required super.occupancyRate,
    required super.revenue,
    required super.date,
    required super.status,
  });
}

class BookingReportRowModel extends BookingReportRow {
  const BookingReportRowModel({
    required super.bookingId,
    required super.clientName,
    required super.tripId,
    required super.amount,
    required super.paymentMethod,
    required super.status,
    required super.date,
  });
}

class RevenueReportRowModel extends RevenueReportRow {
  const RevenueReportRowModel({
    required super.date,
    required super.totalRevenue,
    required super.bookingsRevenue,
    required super.subscriptionsRevenue,
    required super.refundsCount,
    required super.netRevenue,
  });
}

class DriverReportRowModel extends DriverReportRow {
  const DriverReportRowModel({
    required super.driverId,
    required super.name,
    required super.completedTrips,
    required super.totalWorkingHours,
    required super.rating,
    required super.totalRevenue,
    required super.status,
  });
}

class VehicleReportRowModel extends VehicleReportRow {
  const VehicleReportRowModel({
    required super.vehicleId,
    required super.plateNumber,
    required super.model,
    required super.completedTrips,
    required super.fuelConsumption,
    required super.maintenanceStatus,
    required super.status,
  });
}

class SubscriptionReportRowModel extends SubscriptionReportRow {
  const SubscriptionReportRowModel({
    required super.packageName,
    required super.activeUsers,
    required super.expiredUsers,
    required super.totalRevenue,
    required super.renewalsCount,
  });
}

class ComplaintReportRowModel extends ComplaintReportRow {
  const ComplaintReportRowModel({
    required super.category,
    required super.totalComplaints,
    required super.resolvedComplaints,
    required super.avgResolutionTime,
    required super.pendingComplaints,
  });
}

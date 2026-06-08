enum FleetAssignmentStatus {
  active('نشط'),
  ended('منتهي'),
  changed('تم تغييره');

  final String label;

  const FleetAssignmentStatus(this.label);
}

class FleetAssignment {
  final String id;
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehiclePlate;
  final String route;
  final String startedAt;
  final String? endedAt;
  final FleetAssignmentStatus status;
  final String reason;
  final List<AssignmentTimelineEvent> timeline;

  const FleetAssignment({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.route,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.reason,
    required this.timeline,
  });

  FleetAssignment copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? vehicleId,
    String? vehiclePlate,
    String? route,
    String? startedAt,
    String? endedAt,
    bool clearEndedAt = false,
    FleetAssignmentStatus? status,
    String? reason,
    List<AssignmentTimelineEvent>? timeline,
  }) {
    return FleetAssignment(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      route: route ?? this.route,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      timeline: timeline ?? this.timeline,
    );
  }
}

class AssignmentTimelineEvent {
  final String title;
  final String date;
  final String description;

  const AssignmentTimelineEvent({
    required this.title,
    required this.date,
    required this.description,
  });
}

class AssignmentDriverOption {
  final String id;
  final String name;
  final String status;
  final double rating;

  const AssignmentDriverOption({
    required this.id,
    required this.name,
    required this.status,
    required this.rating,
  });
}

class AssignmentVehicleOption {
  final String id;
  final String plateNumber;
  final String model;
  final int capacity;
  final String status;

  const AssignmentVehicleOption({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.capacity,
    required this.status,
  });
}

class FleetAssignmentsData {
  final List<FleetAssignment> assignments;
  final List<AssignmentDriverOption> drivers;
  final List<AssignmentVehicleOption> vehicles;
  final List<String> routes;

  const FleetAssignmentsData({
    required this.assignments,
    required this.drivers,
    required this.vehicles,
    required this.routes,
  });
}

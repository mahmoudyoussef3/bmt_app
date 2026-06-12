/// Fleet assignment entity and status enum.
library;

import 'fleet_common.dart';

enum FleetAssignmentStatus {
  active('نشط'),
  ended('منتهي');

  final String label;

  const FleetAssignmentStatus(this.label);
}

class FleetAssignment {
  final String id;
  final String driverId;
  final String vehicleId;
  final String assignedAt;
  final FleetAssignmentStatus status;
  final List<FleetHistoryItem> history;

  const FleetAssignment({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.assignedAt,
    required this.status,
    this.history = const [],
  });

  FleetAssignment copyWith({
    String? id,
    String? driverId,
    String? vehicleId,
    String? assignedAt,
    FleetAssignmentStatus? status,
    List<FleetHistoryItem>? history,
  }) {
    return FleetAssignment(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      assignedAt: assignedAt ?? this.assignedAt,
      status: status ?? this.status,
      history: history ?? this.history,
    );
  }
}

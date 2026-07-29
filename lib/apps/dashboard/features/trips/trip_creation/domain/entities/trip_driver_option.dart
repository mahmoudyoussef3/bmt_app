/// A driver the operator may schedule, together with the vehicle they operate.
///
/// The trip planner offers exactly one resource choice — the driver — because the
/// office pairs each driver with one bus and that pairing is what dispatch means. The
/// vehicle on this object is *derived* from the driver's active assignment and is shown
/// read-only; it is never something the operator picks, and it is never what the server
/// schedules from (the server re-resolves it from the same assignment). Carrying it
/// here is what lets the planner show the operator which bus they are committing, and
/// refuse — with a reason they can act on — a driver who has none.
library;

class AssignedVehicle {
  final String id;
  final String plateNumber;
  final String vehicleCode;
  final String vehicleType;
  final String brand;
  final String model;
  final int capacity;

  /// The vehicle's own operational status (`active`, `maintenance`, …). A driver whose
  /// bus is not active cannot run a trip, and the planner says which of the two is the
  /// problem rather than refusing without explanation.
  final String status;

  const AssignedVehicle({
    required this.id,
    required this.plateNumber,
    required this.vehicleCode,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.capacity,
    required this.status,
  });

  bool get isSchedulable => status == 'active';

  /// "Toyota Hiace", falling back to whatever identifier the office actually filled in.
  String get displayName {
    final parts = [
      brand.trim(),
      model.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    if (vehicleType.trim().isNotEmpty) return vehicleType.trim();
    return vehicleCode.trim().isNotEmpty ? vehicleCode.trim() : plateNumber;
  }
}

class TripDriverOption {
  final String id;
  final String name;
  final String phone;

  /// The bus this driver currently operates, or null when the office has not paired
  /// them with one. Null is a blocking state for trip creation, not an empty field.
  final AssignedVehicle? assignedVehicle;

  const TripDriverOption({
    required this.id,
    required this.name,
    required this.phone,
    this.assignedVehicle,
  });

  bool get hasVehicle => assignedVehicle != null;

  /// True when this driver can actually be dispatched right now: they hold a bus and
  /// that bus is in service.
  bool get isSchedulable => assignedVehicle?.isSchedulable ?? false;
}

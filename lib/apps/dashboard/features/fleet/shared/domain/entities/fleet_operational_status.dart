/// What a vehicle is *doing*, as opposed to what state its record is in.
///
/// `vehicles.status` answers "may this bus be used?" — it is an intent the
/// operator sets. It has never answered "is this bus out on the road right now?",
/// which is the question a dispatcher actually asks, and which only
/// `operation_trips` can answer. Both are real and they can disagree: a bus can be
/// marked for maintenance while it is halfway to Alexandria. This file keeps them
/// as two separate readings rather than collapsing them into one and losing the
/// contradiction.
///
/// Every value here is derived from data the database already holds. Nothing is
/// invented: `onTrip` and `assigned` come from `operation_trips.status` +
/// `trip_date`, the rest from `vehicles.status`.
library;

import 'fleet_vehicle.dart';

/// A trip that commits a vehicle, reduced to what the fleet screens need.
class FleetVehicleDuty {
  const FleetVehicleDuty({
    required this.vehicleId,
    required this.tripId,
    required this.tripCode,
    required this.status,
    required this.tripDate,
    required this.departureTime,
    this.driverId = '',
    this.routeName = '',
  });

  final String vehicleId;
  final String tripId;
  final String tripCode;

  /// Raw `operation_trips.status`.
  final String status;
  final DateTime tripDate;
  final String departureTime;
  final String driverId;
  final String routeName;

  /// The bus is physically out: boarding passengers or under way.
  bool get isUnderWay => status == 'boarding' || status == 'in_progress';

  /// Committed to a future departure that has not started.
  bool get isUpcoming => status == 'scheduled' || status == 'open_for_booking';
}

enum FleetOperationalStatus {
  /// Active, and no trip is holding it.
  available('متاح'),

  /// Committed to a trip that has not departed.
  assigned('مُعيّن'),

  /// Boarding or under way right now.
  onTrip('في رحلة'),

  /// `vehicles.status = 'maintenance'`.
  maintenance('في الصيانة'),

  /// `vehicles.status = 'suspended'`.
  unavailable('غير متاح'),

  /// `vehicles.status = 'archived'`.
  retired('متقاعد');

  const FleetOperationalStatus(this.label);

  final String label;

  /// Whether a new trip may be scheduled onto a vehicle in this state. Mirrors
  /// `enforce_trip_resource_availability` in the database, which is the authority
  /// — this exists so the dashboard can grey the option out before the operator
  /// fills in a whole wizard and is refused at the end.
  bool get canTakeNewTrip =>
      this == FleetOperationalStatus.available ||
      this == FleetOperationalStatus.assigned ||
      this == FleetOperationalStatus.onTrip;
}

/// Resolves the operational reading for one vehicle.
///
/// Precedence is deliberate: an in-flight trip is an **observation** and outranks
/// the record's intent, so a bus that is genuinely on the road never reads
/// "متاح" or "في الصيانة" while it is carrying passengers. The lifecycle chip is
/// still rendered next to this one, which is what makes such a disagreement
/// visible to the operator instead of hiding it.
FleetOperationalStatus resolveOperationalStatus({
  required FleetVehicle vehicle,
  required Iterable<FleetVehicleDuty> duties,
  DateTime? now,
}) {
  final today = DateUtilsDayOnly.of(now ?? DateTime.now());
  final mine = duties.where((duty) => duty.vehicleId == vehicle.id);

  if (mine.any((duty) => duty.isUnderWay)) return FleetOperationalStatus.onTrip;

  final status = switch (vehicle.status) {
    FleetVehicleStatus.maintenance => FleetOperationalStatus.maintenance,
    FleetVehicleStatus.suspended => FleetOperationalStatus.unavailable,
    FleetVehicleStatus.archived => FleetOperationalStatus.retired,
    FleetVehicleStatus.active => null,
  };
  if (status != null) return status;

  final hasUpcoming = mine.any(
    (duty) =>
        duty.isUpcoming &&
        !DateUtilsDayOnly.of(duty.tripDate).isBefore(today),
  );

  return hasUpcoming
      ? FleetOperationalStatus.assigned
      : FleetOperationalStatus.available;
}

/// Local date-only helper, so a trip departing later today still counts as
/// upcoming rather than being compared against the current clock time.
abstract final class DateUtilsDayOnly {
  static DateTime of(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

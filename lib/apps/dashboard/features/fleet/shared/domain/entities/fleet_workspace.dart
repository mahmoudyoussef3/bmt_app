/// Fleet workspace — aggregate root that re-exports all fleet entities.
///
/// Import this single file to access all fleet types.
/// Individual files can also be imported directly for narrower scope.
library;

export 'fleet_common.dart';
export 'fleet_driver.dart';
export 'fleet_vehicle.dart';
export 'fleet_assignment.dart';
export 'fleet_document.dart';
export 'fleet_operational_status.dart';

import 'fleet_driver.dart';
import 'fleet_vehicle.dart';
import 'fleet_assignment.dart';
import 'fleet_document.dart';
import 'fleet_operational_status.dart';

class FleetWorkspace {
  final List<FleetDriver> drivers;
  final List<FleetVehicle> vehicles;
  final List<FleetAssignment> assignments;
  final List<FleetDocument> documents;

  /// The trips currently committing this office's vehicles and drivers.
  ///
  /// Defaults to empty so every existing caller — and every test that builds a
  /// workspace by hand — keeps compiling and simply reads every active vehicle as
  /// `available`, which is what it read before duties existed.
  final List<FleetVehicleDuty> duties;

  const FleetWorkspace({
    required this.drivers,
    required this.vehicles,
    required this.assignments,
    required this.documents,
    this.duties = const [],
  });

  /// What [vehicle] is doing right now. See [resolveOperationalStatus].
  FleetOperationalStatus operationalStatusOf(FleetVehicle vehicle) =>
      resolveOperationalStatus(vehicle: vehicle, duties: duties);

  /// The trip physically holding [vehicle] right now (boarding/in progress),
  /// or null if it is not out on the road.
  FleetVehicleDuty? underwayDutyOf(FleetVehicle vehicle) =>
      _earliest(duties.where((d) => d.vehicleId == vehicle.id && d.isUnderWay));

  /// The nearest future trip [vehicle] is committed to, excluding one already
  /// under way.
  FleetVehicleDuty? nextDutyOf(FleetVehicle vehicle) =>
      _earliest(duties.where((d) => d.vehicleId == vehicle.id && d.isUpcoming));

  /// The trip holding [vehicle] right now, or the next one it is committed to.
  FleetVehicleDuty? currentDutyOf(FleetVehicle vehicle) =>
      underwayDutyOf(vehicle) ?? nextDutyOf(vehicle);

  /// The vehicle-side helpers above, mirrored for a driver — trips key on
  /// `driver_id` in the exact same `duties` rows, so no extra query is
  /// needed to answer "what is this driver doing".
  FleetVehicleDuty? underwayDutyOfDriver(FleetDriver driver) =>
      _earliest(duties.where((d) => d.driverId == driver.id && d.isUnderWay));

  FleetVehicleDuty? nextDutyOfDriver(FleetDriver driver) =>
      _earliest(duties.where((d) => d.driverId == driver.id && d.isUpcoming));

  FleetVehicleDuty? currentDutyOfDriver(FleetDriver driver) =>
      underwayDutyOfDriver(driver) ?? nextDutyOfDriver(driver);

  static FleetVehicleDuty? _earliest(Iterable<FleetVehicleDuty> duties) {
    final sorted = duties.toList()
      ..sort((a, b) {
        final byDate = a.tripDate.compareTo(b.tripDate);
        return byDate != 0 ? byDate : a.departureTime.compareTo(b.departureTime);
      });
    return sorted.isEmpty ? null : sorted.first;
  }

  FleetSummary get summary {
    final nonArchivedVehicles = vehicles
        .where((vehicle) => vehicle.status != FleetVehicleStatus.archived)
        .toList();
    var inService = 0;
    var unassigned = 0;
    var inMaintenance = 0;
    for (final vehicle in nonArchivedVehicles) {
      switch (operationalStatusOf(vehicle)) {
        case FleetOperationalStatus.onTrip:
        case FleetOperationalStatus.assigned:
          inService++;
        case FleetOperationalStatus.available:
          unassigned++;
        case FleetOperationalStatus.maintenance:
          inMaintenance++;
        case FleetOperationalStatus.unavailable:
        case FleetOperationalStatus.retired:
          break;
      }
    }

    return FleetSummary(
      driversCount: drivers
          .where((driver) => driver.status != FleetDriverStatus.archived)
          .length,
      vehiclesCount: nonArchivedVehicles.length,
      activeAssignmentsCount: assignments
          .where(
            (assignment) => assignment.status == FleetAssignmentStatus.active,
          )
          .length,
      documentsNeedFollowUpCount: documents
          .where(
            (document) =>
                document.status == FleetDocumentStatus.expired ||
                document.status == FleetDocumentStatus.expiringSoon,
          )
          .length,
      inServiceVehiclesCount: inService,
      unassignedVehiclesCount: unassigned,
      inMaintenanceVehiclesCount: inMaintenance,
    );
  }
}

class FleetSummary {
  final int driversCount;
  final int vehiclesCount;
  final int activeAssignmentsCount;
  final int documentsNeedFollowUpCount;

  /// Committed to a trip — on the road right now or booked for one ahead.
  final int inServiceVehiclesCount;

  /// Active and available, but nothing has claimed it.
  final int unassignedVehiclesCount;

  /// `vehicles.status = 'maintenance'`.
  final int inMaintenanceVehiclesCount;

  const FleetSummary({
    required this.driversCount,
    required this.vehiclesCount,
    required this.activeAssignmentsCount,
    required this.documentsNeedFollowUpCount,
    this.inServiceVehiclesCount = 0,
    this.unassignedVehiclesCount = 0,
    this.inMaintenanceVehiclesCount = 0,
  });
}

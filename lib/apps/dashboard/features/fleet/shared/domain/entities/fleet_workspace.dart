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

  /// The trip holding [vehicle] right now, or the next one it is committed to.
  FleetVehicleDuty? currentDutyOf(FleetVehicle vehicle) {
    final mine = duties.where((duty) => duty.vehicleId == vehicle.id).toList();
    if (mine.isEmpty) return null;

    final underWay = mine.where((duty) => duty.isUnderWay);
    if (underWay.isNotEmpty) return underWay.first;

    final upcoming = mine.where((duty) => duty.isUpcoming).toList()
      ..sort((a, b) {
        final byDate = a.tripDate.compareTo(b.tripDate);
        return byDate != 0 ? byDate : a.departureTime.compareTo(b.departureTime);
      });
    return upcoming.isEmpty ? null : upcoming.first;
  }

  FleetSummary get summary {
    return FleetSummary(
      driversCount: drivers
          .where((driver) => driver.status != FleetDriverStatus.archived)
          .length,
      vehiclesCount: vehicles
          .where((vehicle) => vehicle.status != FleetVehicleStatus.archived)
          .length,
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
    );
  }
}

class FleetSummary {
  final int driversCount;
  final int vehiclesCount;
  final int activeAssignmentsCount;
  final int documentsNeedFollowUpCount;

  const FleetSummary({
    required this.driversCount,
    required this.vehiclesCount,
    required this.activeAssignmentsCount,
    required this.documentsNeedFollowUpCount,
  });
}

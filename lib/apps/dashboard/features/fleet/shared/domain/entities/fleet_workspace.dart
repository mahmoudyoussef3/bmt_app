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

import 'fleet_driver.dart';
import 'fleet_vehicle.dart';
import 'fleet_assignment.dart';
import 'fleet_document.dart';

class FleetWorkspace {
  final List<FleetDriver> drivers;
  final List<FleetVehicle> vehicles;
  final List<FleetAssignment> assignments;
  final List<FleetDocument> documents;

  const FleetWorkspace({
    required this.drivers,
    required this.vehicles,
    required this.assignments,
    required this.documents,
  });

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

/// Turns the fleet workspace into a prioritized, actionable "needs your
/// attention" list.
///
/// Every item here reuses [DriverOperations]/[VehicleOperations] — the same
/// eligibility logic that already gates assignment and trip scheduling
/// elsewhere in Fleet — so nothing is invented for this screen alone. If an
/// item is listed here, it corresponds to something that would actually
/// block or complicate a real operation, not a cosmetic flag.
library;

import 'driver_operations.dart';
import 'fleet_workspace.dart';
import 'vehicle_operations.dart';

enum FleetAttentionSeverity { critical, warning }

enum FleetAttentionTarget { driver, vehicle }

class FleetAttentionItem {
  const FleetAttentionItem({
    required this.severity,
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.actionLabel,
  });

  final FleetAttentionSeverity severity;
  final FleetAttentionTarget targetType;
  final String targetId;
  final String title;
  final String subtitle;
  final String reason;
  final String actionLabel;
}

List<FleetAttentionItem> buildFleetAttentionItems(FleetWorkspace workspace) {
  final items = <FleetAttentionItem>[];

  for (final vehicle in workspace.vehicles) {
    final snapshot = VehicleOperations.snapshot(vehicle, workspace);
    if (!snapshot.requiresAttention) continue;
    items.add(
      FleetAttentionItem(
        severity: snapshot.health == VehicleHealthLevel.critical
            ? FleetAttentionSeverity.critical
            : FleetAttentionSeverity.warning,
        targetType: FleetAttentionTarget.vehicle,
        targetId: vehicle.id,
        title: vehicle.vehicleNumber,
        subtitle: '${vehicle.brand} ${vehicle.model}',
        reason: snapshot.primaryReason,
        actionLabel: 'فتح المركبة',
      ),
    );
  }

  for (final driver in workspace.drivers) {
    final snapshot = DriverOperations.snapshot(driver, workspace);
    if (!snapshot.requiresAttention) continue;
    items.add(
      FleetAttentionItem(
        severity: snapshot.health == DriverHealthLevel.critical
            ? FleetAttentionSeverity.critical
            : FleetAttentionSeverity.warning,
        targetType: FleetAttentionTarget.driver,
        targetId: driver.id,
        title: driver.fullName,
        subtitle: driver.employeeCode,
        reason: snapshot.primaryReason,
        actionLabel: 'فتح ملف السائق',
      ),
    );
  }

  items.sort((a, b) {
    if (a.severity == b.severity) return 0;
    return a.severity == FleetAttentionSeverity.critical ? -1 : 1;
  });

  return items;
}

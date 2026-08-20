/// The vehicle-side mirror of `DriverOperations`: reduces a vehicle's raw
/// status, live duties, and document set into one health reading plus the
/// concrete reasons behind it, so a screen never has to explain "needs
/// attention" without saying why.
library;

import 'fleet_workspace.dart';

enum VehicleHealthLevel {
  healthy('سليمة'),
  warning('تنبيه'),
  critical('حرجة');

  const VehicleHealthLevel(this.label);

  final String label;
}

class VehicleOperationsSnapshot {
  const VehicleOperationsSnapshot({
    required this.operationalStatus,
    required this.health,
    required this.primaryReason,
    required this.attentionReasons,
    required this.currentDriver,
    required this.currentDuty,
  });

  final FleetOperationalStatus operationalStatus;
  final VehicleHealthLevel health;
  final String primaryReason;
  final List<String> attentionReasons;
  final FleetDriver? currentDriver;
  final FleetVehicleDuty? currentDuty;

  bool get requiresAttention => health != VehicleHealthLevel.healthy;
}

class VehicleOperations {
  const VehicleOperations._();

  static VehicleOperationsSnapshot snapshot(
    FleetVehicle vehicle,
    FleetWorkspace workspace,
  ) {
    final attention = <String>[];

    if (vehicle.status == FleetVehicleStatus.maintenance) {
      attention.add('المركبة في الصيانة');
    }
    if (vehicle.status == FleetVehicleStatus.suspended) {
      attention.add('المركبة موقوفة');
    }

    // Same documents already joined into `vehicle.licenseExpiry` /
    // `.insuranceExpiry` / `.inspectionExpiry` by the datasource — read from
    // the workspace instead so a missing document type gets its own named
    // reason rather than collapsing into one generic "documents" flag.
    for (final doc in workspace.documents.where(
      (doc) => doc.ownerId == vehicle.id,
    )) {
      if (doc.status == FleetDocumentStatus.expired) {
        attention.add('${doc.type.label} منتهي الصلاحية');
      } else if (doc.status == FleetDocumentStatus.expiringSoon) {
        attention.add('${doc.type.label} يقترب من الانتهاء');
      }
    }

    FleetDriver? currentDriver;
    if (vehicle.currentDriverId.isNotEmpty) {
      for (final driver in workspace.drivers) {
        if (driver.id == vehicle.currentDriverId) {
          currentDriver = driver;
          break;
        }
      }
    }

    if (vehicle.status == FleetVehicleStatus.active &&
        vehicle.currentDriverId.isEmpty) {
      attention.add('لا يوجد سائق معين لهذه المركبة');
    }

    final health = _healthFor(vehicle, attention);

    return VehicleOperationsSnapshot(
      operationalStatus: workspace.operationalStatusOf(vehicle),
      health: health,
      primaryReason: attention.isEmpty ? 'جاهزة للتشغيل' : attention.first,
      attentionReasons: attention,
      currentDriver: currentDriver,
      currentDuty: workspace.currentDutyOf(vehicle),
    );
  }

  static VehicleHealthLevel _healthFor(
    FleetVehicle vehicle,
    List<String> attention,
  ) {
    if (vehicle.status == FleetVehicleStatus.suspended) {
      return VehicleHealthLevel.critical;
    }
    if (attention.any((reason) => reason.contains('منتهي'))) {
      return VehicleHealthLevel.critical;
    }
    if (attention.isNotEmpty) return VehicleHealthLevel.warning;
    return VehicleHealthLevel.healthy;
  }
}

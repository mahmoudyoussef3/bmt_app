import 'fleet_workspace.dart';

enum DriverOperationalStatus {
  available('متاح'),
  assigned('معين'),
  blocked('غير مؤهل'),
  suspended('موقوف'),
  archived('مؤرشف');

  const DriverOperationalStatus(this.label);

  final String label;
}

enum DriverHealthLevel {
  healthy('سليم'),
  warning('تنبيه'),
  critical('حرج');

  const DriverHealthLevel(this.label);

  final String label;
}

class DriverOperationsSnapshot {
  const DriverOperationsSnapshot({
    required this.status,
    required this.health,
    required this.primaryReason,
    required this.attentionReasons,
    required this.assignedVehicle,
    required this.activeAssignments,
  });

  final DriverOperationalStatus status;
  final DriverHealthLevel health;
  final String primaryReason;
  final List<String> attentionReasons;
  final FleetVehicle? assignedVehicle;
  final List<FleetAssignment> activeAssignments;

  bool get canAssign =>
      status == DriverOperationalStatus.available &&
      health != DriverHealthLevel.critical;

  bool get requiresAttention => health != DriverHealthLevel.healthy;
}

class DriverOperations {
  const DriverOperations._();

  static DriverOperationsSnapshot snapshot(
    FleetDriver driver,
    FleetWorkspace workspace,
  ) {
    final activeAssignments = workspace.assignments
        .where(
          (assignment) =>
              assignment.driverId == driver.id &&
              assignment.status == FleetAssignmentStatus.active,
        )
        .toList();

    final assignedVehicle = _vehicleFor(driver, activeAssignments, workspace);
    final attention = <String>[];

    if (driver.status == FleetDriverStatus.suspended) {
      attention.add('السائق موقوف إدارياً');
    }
    if (driver.status == FleetDriverStatus.archived) {
      attention.add('السائق مؤرشف');
    }

    final licenseState = _licenseState(driver.licenseExpiryDate);
    if (licenseState == _LicenseState.expired) {
      attention.add('رخصة القيادة منتهية');
    } else if (licenseState == _LicenseState.expiringSoon) {
      attention.add('رخصة القيادة قاربت على الانتهاء');
    }

    final documents = driver.documents.isNotEmpty
        ? driver.documents
        : workspace.documents.where((doc) => doc.ownerId == driver.id).toList();

    if (documents.any((doc) => doc.status == FleetDocumentStatus.expired)) {
      attention.add('يوجد مستند منتهي');
    }
    if (documents.any(
      (doc) => doc.status == FleetDocumentStatus.expiringSoon,
    )) {
      attention.add('يوجد مستند قارب على الانتهاء');
    }
    if (!documents.any((doc) => doc.type == FleetDocumentType.driverLicense)) {
      attention.add('مستند رخصة القيادة غير مرفوع');
    }

    if (activeAssignments.length > 1) {
      attention.add('تعارض في تعيينات المركبات');
    }
    if (assignedVehicle != null &&
        assignedVehicle.status != FleetVehicleStatus.active) {
      attention.add('المركبة المعينة غير جاهزة للتشغيل');
    }

    final health = _healthFor(driver, attention);
    final status = _statusFor(driver, activeAssignments, health);

    return DriverOperationsSnapshot(
      status: status,
      health: health,
      primaryReason: attention.isEmpty ? 'جاهز للتشغيل' : attention.first,
      attentionReasons: attention,
      assignedVehicle: assignedVehicle,
      activeAssignments: activeAssignments,
    );
  }

  static FleetVehicle? _vehicleFor(
    FleetDriver driver,
    List<FleetAssignment> activeAssignments,
    FleetWorkspace workspace,
  ) {
    final vehicleId = driver.currentVehicleId.isNotEmpty
        ? driver.currentVehicleId
        : activeAssignments.isNotEmpty
        ? activeAssignments.first.vehicleId
        : '';
    if (vehicleId.isEmpty) return null;

    for (final vehicle in workspace.vehicles) {
      if (vehicle.id == vehicleId) return vehicle;
    }
    return null;
  }

  static DriverHealthLevel _healthFor(
    FleetDriver driver,
    List<String> attention,
  ) {
    if (driver.status == FleetDriverStatus.suspended ||
        driver.status == FleetDriverStatus.archived) {
      return DriverHealthLevel.critical;
    }
    final criticalReasons = ['منتهية', 'تعارض', 'غير جاهزة'];
    if (attention.any((reason) {
      return criticalReasons.any(reason.contains);
    })) {
      return DriverHealthLevel.critical;
    }
    if (attention.isNotEmpty) return DriverHealthLevel.warning;
    return DriverHealthLevel.healthy;
  }

  static DriverOperationalStatus _statusFor(
    FleetDriver driver,
    List<FleetAssignment> activeAssignments,
    DriverHealthLevel health,
  ) {
    if (driver.status == FleetDriverStatus.archived) {
      return DriverOperationalStatus.archived;
    }
    if (driver.status == FleetDriverStatus.suspended) {
      return DriverOperationalStatus.suspended;
    }
    if (health == DriverHealthLevel.critical) {
      return DriverOperationalStatus.blocked;
    }
    if (activeAssignments.isNotEmpty || driver.currentVehicleId.isNotEmpty) {
      return DriverOperationalStatus.assigned;
    }
    return DriverOperationalStatus.available;
  }

  static _LicenseState _licenseState(String expiryText) {
    final expiry = DateTime.tryParse(expiryText);
    if (expiry == null) return _LicenseState.missing;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(expiry.year, expiry.month, expiry.day);
    final days = expiryOnly.difference(todayOnly).inDays;

    if (days < 0) return _LicenseState.expired;
    if (days <= 30) return _LicenseState.expiringSoon;
    return _LicenseState.valid;
  }
}

enum _LicenseState { valid, expiringSoon, expired, missing }

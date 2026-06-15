import '../../shared/domain/entities/fleet_workspace.dart';

class FleetDriverModel extends FleetDriver {
  const FleetDriverModel({
    required super.id,
    required super.employeeCode,
    required super.fullName,
    required super.phone,
    required super.emergencyPhone,
    required super.address,
    required super.nationalId,
    required super.profileImageUrl,
    required super.licenseNumber,
    required super.licenseExpiryDate,
    required super.hireDate,
    required super.notes,
    required super.status,
    super.currentVehicleId,
    super.createdAt,
    super.updatedAt,
    super.tripHistory,
    super.violations,
    super.documents,
    super.activityTimeline,
  });

  factory FleetDriverModel.fromEntity(FleetDriver driver) {
    return FleetDriverModel(
      id: driver.id,
      employeeCode: driver.employeeCode,
      fullName: driver.fullName,
      phone: driver.phone,
      emergencyPhone: driver.emergencyPhone,
      address: driver.address,
      nationalId: driver.nationalId,
      profileImageUrl: driver.profileImageUrl,
      licenseNumber: driver.licenseNumber,
      licenseExpiryDate: driver.licenseExpiryDate,
      hireDate: driver.hireDate,
      notes: driver.notes,
      status: driver.status,
      currentVehicleId: driver.currentVehicleId,
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt,
      tripHistory: driver.tripHistory,
      violations: driver.violations,
      documents: driver.documents,
      activityTimeline: driver.activityTimeline,
    );
  }

  factory FleetDriverModel.fromJson(
    Map<String, dynamic> json, {
    String currentVehicleId = '',
    List<FleetDocument> documents = const [],
  }) {
    return FleetDriverModel(
      id: json['id'] as String? ?? '',
      employeeCode: json['employee_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      emergencyPhone:
          json['emergency_phone'] as String? ??
          json['emergency_contact'] as String? ??
          '',
      address: json['address'] as String? ?? '',
      nationalId: json['national_id'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      licenseExpiryDate:
          json['license_expiry_date'] as String? ??
          json['license_expiry'] as String? ??
          '',
      hireDate: json['hire_date'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: FleetDriverStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FleetDriverStatus.active,
      ),
      currentVehicleId: currentVehicleId,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      documents: documents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'employee_code': employeeCode,
      'full_name': fullName,
      'phone': phone,
      'emergency_phone': emergencyPhone,
      'address': address,
      'national_id': nationalId,
      'profile_image_url': profileImageUrl,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate,
      'notes': notes,
      'hire_date': hireDate,
      'status': status.name,
    };
  }
}

class FleetVehicleModel extends FleetVehicle {
  const FleetVehicleModel({
    required super.id,
    required super.vehicleCode,
    required super.plateNumber,
    required super.vehicleType,
    required super.brand,
    required super.model,
    required super.manufactureYear,
    required super.color,
    required super.capacity,
    required super.seatLayoutType,
    required super.imageUrl,
    required super.notes,
    required super.status,
    super.currentDriverId,
    super.createdAt,
    super.updatedAt,
    required super.seatConfiguration,
    required super.licenseExpiry,
    required super.insuranceExpiry,
    required super.inspectionExpiry,
    super.images,
    super.previousDrivers,
    super.tripHistory,
    super.timeline,
  });

  factory FleetVehicleModel.fromEntity(FleetVehicle vehicle) {
    return FleetVehicleModel(
      id: vehicle.id,
      vehicleCode: vehicle.vehicleCode,
      plateNumber: vehicle.plateNumber,
      vehicleType: vehicle.vehicleType,
      brand: vehicle.brand,
      model: vehicle.model,
      manufactureYear: vehicle.manufactureYear,
      color: vehicle.color,
      capacity: vehicle.capacity,
      seatLayoutType: vehicle.seatLayoutType,
      imageUrl: vehicle.imageUrl,
      notes: vehicle.notes,
      status: vehicle.status,
      currentDriverId: vehicle.currentDriverId,
      createdAt: vehicle.createdAt,
      updatedAt: vehicle.updatedAt,
      seatConfiguration: vehicle.seatConfiguration,
      licenseExpiry: vehicle.licenseExpiry,
      insuranceExpiry: vehicle.insuranceExpiry,
      inspectionExpiry: vehicle.inspectionExpiry,
      images: vehicle.images,
      previousDrivers: vehicle.previousDrivers,
      tripHistory: vehicle.tripHistory,
      timeline: vehicle.timeline,
    );
  }

  factory FleetVehicleModel.fromJson(
    Map<String, dynamic> json, {
    String currentDriverId = '',
    String licenseExpiry = '',
    String insuranceExpiry = '',
    String inspectionExpiry = '',
  }) {
    final imgUrl =
        json['image_url'] as String? ?? json['image_label'] as String? ?? '';
    final List<FleetVehicleImage> parsedImages = imgUrl.isNotEmpty
        ? imgUrl.split(',').map((url) => FleetVehicleImage(url: url)).toList()
        : const [];

    return FleetVehicleModel(
      id: json['id'] as String? ?? '',
      vehicleCode:
          json['vehicle_code'] as String? ??
          json['vehicle_number'] as String? ??
          '',
      plateNumber: json['plate_number'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      manufactureYear:
          json['manufacture_year'] as int? ?? json['model_year'] as int? ?? 0,
      color: json['color'] as String? ?? '',
      capacity: json['capacity'] as int? ?? json['seats_count'] as int? ?? 0,
      seatLayoutType: json['seat_layout_type'] as String? ?? '',
      imageUrl: imgUrl,
      notes: json['notes'] as String? ?? '',
      status: FleetVehicleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FleetVehicleStatus.active,
      ),
      currentDriverId: currentDriverId,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      seatConfiguration: json['seat_configuration'] != null
          ? SeatConfiguration.fromJson(
              json['seat_configuration'] as Map<String, dynamic>,
            )
          : SeatConfiguration.empty(),
      licenseExpiry: licenseExpiry,
      insuranceExpiry: insuranceExpiry,
      inspectionExpiry: inspectionExpiry,
      images: parsedImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'vehicle_code': vehicleCode,
      'plate_number': plateNumber,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'manufacture_year': manufactureYear,
      'color': color,
      'capacity': capacity,
      'seat_layout_type': seatLayoutType,
      'image_url': images.isNotEmpty
          ? images.map((i) => i.url).join(',')
          : imageUrl,
      'notes': notes,
      'status': status.name,
      'seat_configuration': _standardSeatConfiguration(
        seatConfiguration,
      ).toJson(),
    };
  }
}

SeatConfiguration _standardSeatConfiguration(SeatConfiguration configuration) {
  return SeatConfiguration(
    rows: configuration.rows,
    columns: configuration.columns,
    seats: configuration.seats.map((seat) {
      final type = switch (seat.seatType) {
        'driver' => 'driver',
        'empty' => 'empty',
        _ => 'passenger',
      };
      return SeatLayoutItem(
        seatNumber: seat.seatNumber,
        seatType: type,
        row: seat.row,
        column: seat.column,
      );
    }).toList(),
  );
}

class FleetAssignmentModel extends FleetAssignment {
  const FleetAssignmentModel({
    required super.id,
    required super.driverId,
    required super.vehicleId,
    required super.assignedAt,
    required super.status,
    super.history,
  });

  factory FleetAssignmentModel.fromEntity(FleetAssignment assignment) {
    return FleetAssignmentModel(
      id: assignment.id,
      driverId: assignment.driverId,
      vehicleId: assignment.vehicleId,
      assignedAt: assignment.assignedAt,
      status: assignment.status,
      history: assignment.history,
    );
  }

  factory FleetAssignmentModel.fromJson(Map<String, dynamic> json) {
    final historyList =
        (json['history'] as List?)
            ?.map((h) => FleetHistoryItem.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];
    return FleetAssignmentModel(
      id: json['id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      assignedAt: json['assigned_at'] as String? ?? '',
      status: FleetAssignmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FleetAssignmentStatus.active,
      ),
      history: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'assigned_at': assignedAt,
      'status': status.name,
      'history': history.map((h) => h.toJson()).toList(),
    };
  }
}

class FleetDocumentModel extends FleetDocument {
  const FleetDocumentModel({
    required super.id,
    required super.type,
    required super.ownerId,
    required super.ownerName,
    required super.referenceNumber,
    required super.expiryDate,
    required super.status,
    super.fileUrl,
  });

  factory FleetDocumentModel.fromJson(
    Map<String, dynamic> json, {
    String ownerName = '',
  }) {
    final isDriver = json.containsKey('driver_id');
    final ownerId =
        (isDriver ? json['driver_id'] : json['vehicle_id']) as String? ?? '';
    return FleetDocumentModel(
      id: json['id'] as String? ?? '',
      type: _parseDocumentType(json['type'] as String? ?? ''),
      ownerId: ownerId,
      ownerName: ownerName,
      referenceNumber: json['id'] as String? ?? '',
      expiryDate: json['expiry_date'] as String? ?? '',
      status: _parseDocumentStatus(json['status'] as String? ?? ''),
      fileUrl: json['file_url'] as String? ?? '',
    );
  }

  factory FleetDocumentModel.empty() {
    return const FleetDocumentModel(
      id: '',
      type: FleetDocumentType.other,
      ownerId: '',
      ownerName: '',
      referenceNumber: '',
      expiryDate: '',
      status: FleetDocumentStatus.valid,
      fileUrl: '',
    );
  }
}

FleetDocumentType _parseDocumentType(String value) {
  return switch (value) {
    'driver_license' || 'driverLicense' => FleetDocumentType.driverLicense,
    'national_id_front' ||
    'nationalIdFront' => FleetDocumentType.nationalIdFront,
    'national_id_back' || 'nationalIdBack' => FleetDocumentType.nationalIdBack,
    'criminal_record' || 'criminalRecord' => FleetDocumentType.criminalRecord,
    'employment_contract' ||
    'employmentContract' => FleetDocumentType.employmentContract,
    'vehicle_license' || 'vehicleLicense' => FleetDocumentType.vehicleLicense,
    'insurance' => FleetDocumentType.insurance,
    'inspection' || 'technical_inspection' => FleetDocumentType.inspection,
    _ => FleetDocumentType.other,
  };
}

FleetDocumentStatus _parseDocumentStatus(String value) {
  return switch (value) {
    'expired' => FleetDocumentStatus.expired,
    'expiring_soon' || 'expiringSoon' => FleetDocumentStatus.expiringSoon,
    'valid' => FleetDocumentStatus.valid,
    _ => FleetDocumentStatus.valid,
  };
}

String documentTypeToDbString(FleetDocumentType type) {
  return switch (type) {
    FleetDocumentType.driverLicense => 'driver_license',
    FleetDocumentType.nationalIdFront => 'national_id_front',
    FleetDocumentType.nationalIdBack => 'national_id_back',
    FleetDocumentType.criminalRecord => 'criminal_record',
    FleetDocumentType.employmentContract => 'employment_contract',
    FleetDocumentType.vehicleLicense => 'vehicle_license',
    FleetDocumentType.insurance => 'insurance',
    FleetDocumentType.inspection => 'inspection',
    FleetDocumentType.other => 'other',
  };
}

String documentStatusToDbString(FleetDocumentStatus status) {
  return switch (status) {
    FleetDocumentStatus.expired => 'expired',
    FleetDocumentStatus.expiringSoon => 'expiring_soon',
    FleetDocumentStatus.valid => 'valid',
  };
}

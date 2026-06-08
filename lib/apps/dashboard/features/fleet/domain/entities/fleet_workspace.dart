enum FleetDriverStatus {
  active('نشط'),
  suspended('موقوف'),
  archived('مؤرشف');

  final String label;

  const FleetDriverStatus(this.label);
}

enum FleetVehicleStatus {
  active('نشطة'),
  maintenance('صيانة'),
  suspended('موقوفة'),
  archived('مؤرشفة');

  final String label;

  const FleetVehicleStatus(this.label);
}

enum FleetAssignmentStatus {
  active('نشط'),
  ended('منتهي');

  final String label;

  const FleetAssignmentStatus(this.label);
}

enum FleetDocumentStatus {
  expired('منتهي'),
  expiringSoon('ينتهي قريباً'),
  valid('سليم');

  final String label;

  const FleetDocumentStatus(this.label);
}

enum FleetDocumentType {
  driverLicense('رخصة سائق'),
  vehicleLicense('رخصة مركبة'),
  insurance('التأمين'),
  inspection('الفحص الفني');

  final String label;

  const FleetDocumentType(this.label);
}

enum FleetSortField {
  name,
  status,
  licenseExpiry,
  seats,
  modelYear,
  assignedAt,
}

enum FleetTab {
  drivers('السائقون'),
  vehicles('المركبات'),
  assignments('التعيينات'),
  documents('الوثائق');

  final String label;

  const FleetTab(this.label);
}

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

class FleetDriver {
  final String id;
  final String imageLabel;
  final String name;
  final String phone;
  final String nationalId;
  final String licenseNumber;
  final String licenseExpiry;
  final FleetDriverStatus status;
  final String currentVehicleId;
  final String address;
  final String emergencyContact;
  final List<FleetHistoryItem> tripHistory;
  final List<FleetHistoryItem> violations;
  final List<FleetDocument> documents;
  final List<FleetHistoryItem> activityTimeline;

  const FleetDriver({
    required this.id,
    required this.imageLabel,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
    this.currentVehicleId = '',
    required this.address,
    required this.emergencyContact,
    this.tripHistory = const [],
    this.violations = const [],
    this.documents = const [],
    this.activityTimeline = const [],
  });

  FleetDriver copyWith({
    String? id,
    String? imageLabel,
    String? name,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    String? licenseExpiry,
    FleetDriverStatus? status,
    String? currentVehicleId,
    bool clearCurrentVehicle = false,
    String? address,
    String? emergencyContact,
    List<FleetHistoryItem>? tripHistory,
    List<FleetHistoryItem>? violations,
    List<FleetDocument>? documents,
    List<FleetHistoryItem>? activityTimeline,
  }) {
    return FleetDriver(
      id: id ?? this.id,
      imageLabel: imageLabel ?? this.imageLabel,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      status: status ?? this.status,
      currentVehicleId: clearCurrentVehicle
          ? ''
          : currentVehicleId ?? this.currentVehicleId,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      tripHistory: tripHistory ?? this.tripHistory,
      violations: violations ?? this.violations,
      documents: documents ?? this.documents,
      activityTimeline: activityTimeline ?? this.activityTimeline,
    );
  }
}

class FleetVehicle {
  final String id;
  final String imageLabel;
  final String vehicleNumber;
  final String plateNumber;
  final String model;
  final int modelYear;
  final int seatsCount;
  final String currentDriverId;
  final FleetVehicleStatus status;
  final String licenseExpiry;
  final String insuranceExpiry;
  final String inspectionExpiry;
  final List<FleetVehicleImage> images;
  final List<FleetHistoryItem> previousDrivers;
  final List<FleetHistoryItem> tripHistory;
  final List<FleetHistoryItem> timeline;

  const FleetVehicle({
    required this.id,
    required this.imageLabel,
    required this.vehicleNumber,
    required this.plateNumber,
    required this.model,
    required this.modelYear,
    required this.seatsCount,
    this.currentDriverId = '',
    required this.status,
    required this.licenseExpiry,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    this.images = const [],
    this.previousDrivers = const [],
    this.tripHistory = const [],
    this.timeline = const [],
  });

  FleetVehicle copyWith({
    String? id,
    String? imageLabel,
    String? vehicleNumber,
    String? plateNumber,
    String? model,
    int? modelYear,
    int? seatsCount,
    String? currentDriverId,
    bool clearCurrentDriver = false,
    FleetVehicleStatus? status,
    String? licenseExpiry,
    String? insuranceExpiry,
    String? inspectionExpiry,
    List<FleetVehicleImage>? images,
    List<FleetHistoryItem>? previousDrivers,
    List<FleetHistoryItem>? tripHistory,
    List<FleetHistoryItem>? timeline,
  }) {
    return FleetVehicle(
      id: id ?? this.id,
      imageLabel: imageLabel ?? this.imageLabel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      plateNumber: plateNumber ?? this.plateNumber,
      model: model ?? this.model,
      modelYear: modelYear ?? this.modelYear,
      seatsCount: seatsCount ?? this.seatsCount,
      currentDriverId: clearCurrentDriver
          ? ''
          : currentDriverId ?? this.currentDriverId,
      status: status ?? this.status,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      images: images ?? this.images,
      previousDrivers: previousDrivers ?? this.previousDrivers,
      tripHistory: tripHistory ?? this.tripHistory,
      timeline: timeline ?? this.timeline,
    );
  }
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

class FleetDocument {
  final String id;
  final FleetDocumentType type;
  final String ownerId;
  final String ownerName;
  final String referenceNumber;
  final String expiryDate;
  final FleetDocumentStatus status;

  const FleetDocument({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.referenceNumber,
    required this.expiryDate,
    required this.status,
  });
}

class FleetVehicleImage {
  final String label;
  final String description;

  const FleetVehicleImage({required this.label, required this.description});
}

class FleetHistoryItem {
  final String title;
  final String date;
  final String description;

  const FleetHistoryItem({
    required this.title,
    required this.date,
    required this.description,
  });
}

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
  nationalIdFront('الرقم القومي (أمام)'),
  nationalIdBack('الرقم القومي (خلف)'),
  criminalRecord('الفيش والتشبيه'),
  employmentContract('عقد العمل'),
  vehicleLicense('رخصة مركبة'),
  insurance('التأمين'),
  inspection('الفحص الفني'),
  other('وثائق أخرى');

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
  final String employeeCode;
  final String fullName;
  final String phone;
  final String emergencyPhone;
  final String address;
  final String nationalId;
  final String profileImageUrl;
  final String licenseNumber;
  final String licenseExpiryDate;
  final String hireDate;
  final String notes;
  final FleetDriverStatus status;
  final String currentVehicleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<FleetHistoryItem> tripHistory;
  final List<FleetHistoryItem> violations;
  final List<FleetDocument> documents;
  final List<FleetHistoryItem> activityTimeline;

  const FleetDriver({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.phone,
    required this.emergencyPhone,
    required this.address,
    required this.nationalId,
    required this.profileImageUrl,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.hireDate,
    required this.notes,
    required this.status,
    this.currentVehicleId = '',
    this.createdAt,
    this.updatedAt,
    this.tripHistory = const [],
    this.violations = const [],
    this.documents = const [],
    this.activityTimeline = const [],
  });

  // Legacy compatibility getters:
  String get name => fullName;
  String get emergencyContact => emergencyPhone;
  String get licenseExpiry => licenseExpiryDate;
  String get imageLabel => fullName.isNotEmpty ? fullName.substring(0, 1) : '';

  FleetDriver copyWith({
    String? id,
    String? employeeCode,
    String? fullName,
    String? phone,
    String? emergencyPhone,
    String? address,
    String? nationalId,
    String? profileImageUrl,
    String? licenseNumber,
    String? licenseExpiryDate,
    String? hireDate,
    String? notes,
    FleetDriverStatus? status,
    String? currentVehicleId,
    bool clearCurrentVehicle = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FleetHistoryItem>? tripHistory,
    List<FleetHistoryItem>? violations,
    List<FleetDocument>? documents,
    List<FleetHistoryItem>? activityTimeline,
  }) {
    return FleetDriver(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      hireDate: hireDate ?? this.hireDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      currentVehicleId: clearCurrentVehicle
          ? ''
          : currentVehicleId ?? this.currentVehicleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tripHistory: tripHistory ?? this.tripHistory,
      violations: violations ?? this.violations,
      documents: documents ?? this.documents,
      activityTimeline: activityTimeline ?? this.activityTimeline,
    );
  }
}

class SeatLayoutItem {
  final String seatNumber;
  final String seatType; // driver, passenger, empty, vip, etc.
  final int row;
  final int column;

  const SeatLayoutItem({
    required this.seatNumber,
    required this.seatType,
    required this.row,
    required this.column,
  });

  Map<String, dynamic> toJson() => {
        'seat_number': seatNumber,
        'seat_type': seatType,
        'row': row,
        'column': column,
      };

  factory SeatLayoutItem.fromJson(Map<String, dynamic> json) {
    return SeatLayoutItem(
      seatNumber: json['seat_number'] as String,
      seatType: json['seat_type'] as String,
      row: json['row'] as int,
      column: json['column'] as int,
    );
  }
}

class SeatConfiguration {
  final int rows;
  final int columns;
  final List<SeatLayoutItem> seats;

  const SeatConfiguration({
    required this.rows,
    required this.columns,
    required this.seats,
  });

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'columns': columns,
        'seats': seats.map((s) => s.toJson()).toList(),
      };

  factory SeatConfiguration.fromJson(Map<String, dynamic> json) {
    return SeatConfiguration(
      rows: json['rows'] as int,
      columns: json['columns'] as int,
      seats: (json['seats'] as List?)
              ?.map((s) => SeatLayoutItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory SeatConfiguration.empty() {
    return const SeatConfiguration(rows: 0, columns: 0, seats: []);
  }

  factory SeatConfiguration.generateDefault(int capacity) {
    // Generate a default layout grid of rows and columns based on capacity.
    // e.g. Driver is at (1, 1), empty space at (1, 2)
    final List<SeatLayoutItem> seats = [];
    seats.add(const SeatLayoutItem(seatNumber: 'D', seatType: 'driver', row: 1, column: 1));
    
    int seatNum = 1;
    int curRow = 1;
    // Row 1 column 3 is a passenger seat
    if (seatNum <= capacity) {
      seats.add(SeatLayoutItem(seatNumber: '$seatNum', seatType: 'passenger', row: 1, column: 3));
      seatNum++;
    }

    curRow = 2;
    while (seatNum <= capacity) {
      for (int col = 1; col <= 3; col++) {
        if (seatNum > capacity) break;
        seats.add(SeatLayoutItem(seatNumber: '$seatNum', seatType: 'passenger', row: curRow, column: col));
        seatNum++;
      }
      curRow++;
    }

    return SeatConfiguration(
      rows: curRow - 1,
      columns: 3,
      seats: seats,
    );
  }
}

class FleetVehicle {
  final String id;
  final String vehicleCode;
  final String plateNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final int manufactureYear;
  final String color;
  final int capacity;
  final String seatLayoutType;
  final String imageUrl;
  final String notes;
  final FleetVehicleStatus status;
  final String currentDriverId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SeatConfiguration seatConfiguration;
  final String licenseExpiry;
  final String insuranceExpiry;
  final String inspectionExpiry;
  final List<FleetVehicleImage> images;
  final List<FleetHistoryItem> previousDrivers;
  final List<FleetHistoryItem> tripHistory;
  final List<FleetHistoryItem> timeline;

  const FleetVehicle({
    required this.id,
    required this.vehicleCode,
    required this.plateNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.manufactureYear,
    required this.color,
    required this.capacity,
    required this.seatLayoutType,
    required this.imageUrl,
    required this.notes,
    required this.status,
    this.currentDriverId = '',
    this.createdAt,
    this.updatedAt,
    required this.seatConfiguration,
    required this.licenseExpiry,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    this.images = const [],
    this.previousDrivers = const [],
    this.tripHistory = const [],
    this.timeline = const [],
  });

  // Legacy compatibility getters:
  String get vehicleNumber => vehicleCode;
  int get modelYear => manufactureYear;
  int get seatsCount => capacity;
  String get imageLabel => vehicleCode;

  FleetVehicle copyWith({
    String? id,
    String? vehicleCode,
    String? plateNumber,
    String? vehicleType,
    String? brand,
    String? model,
    int? manufactureYear,
    String? color,
    int? capacity,
    String? seatLayoutType,
    String? imageUrl,
    String? notes,
    FleetVehicleStatus? status,
    String? currentDriverId,
    bool clearCurrentDriver = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SeatConfiguration? seatConfiguration,
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
      vehicleCode: vehicleCode ?? this.vehicleCode,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      manufactureYear: manufactureYear ?? this.manufactureYear,
      color: color ?? this.color,
      capacity: capacity ?? this.capacity,
      seatLayoutType: seatLayoutType ?? this.seatLayoutType,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      currentDriverId: clearCurrentDriver
          ? ''
          : currentDriverId ?? this.currentDriverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seatConfiguration: seatConfiguration ?? this.seatConfiguration,
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
  final String fileUrl;

  const FleetDocument({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.referenceNumber,
    required this.expiryDate,
    required this.status,
    this.fileUrl = '',
  });

  factory FleetDocument.empty() {
    return const FleetDocument(
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

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'description': description,
      };

  factory FleetHistoryItem.fromJson(Map<String, dynamic> json) {
    return FleetHistoryItem(
      title: json['title'] as String,
      date: json['date'] as String,
      description: json['description'] as String,
    );
  }
}

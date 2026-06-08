enum VehicleStatus {
  active('نشطة'),
  outOfService('خارج الخدمة'),
  maintenance('في الصيانة'),
  pendingAssignment('بانتظار التعيين');

  final String label;

  const VehicleStatus(this.label);
}

class Vehicle {
  final String id;
  final String plateNumber;
  final String type;
  final String model;
  final int capacity;
  final VehicleStatus status;
  final String currentDriver;
  final String currentRoute;
  final String licenseExpiry;
  final String insuranceExpiry;
  final String inspectionExpiry;
  final String imageLabel;
  final List<VehicleGalleryImage> gallery;
  final List<VehicleDocument> documents;
  final List<VehicleMaintenance> maintenance;
  final List<VehicleTrip> trips;
  final List<String> previousDrivers;
  final List<String> notes;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.type,
    required this.model,
    required this.capacity,
    required this.status,
    required this.currentDriver,
    required this.currentRoute,
    required this.licenseExpiry,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    required this.imageLabel,
    this.gallery = const [],
    required this.documents,
    required this.maintenance,
    required this.trips,
    required this.previousDrivers,
    required this.notes,
  });

  Vehicle copyWith({
    String? id,
    String? plateNumber,
    String? type,
    String? model,
    int? capacity,
    VehicleStatus? status,
    String? currentDriver,
    String? currentRoute,
    String? licenseExpiry,
    String? insuranceExpiry,
    String? inspectionExpiry,
    String? imageLabel,
    List<VehicleGalleryImage>? gallery,
    List<VehicleDocument>? documents,
    List<VehicleMaintenance>? maintenance,
    List<VehicleTrip>? trips,
    List<String>? previousDrivers,
    List<String>? notes,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentDriver: currentDriver ?? this.currentDriver,
      currentRoute: currentRoute ?? this.currentRoute,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      imageLabel: imageLabel ?? this.imageLabel,
      gallery: gallery ?? this.gallery,
      documents: documents ?? this.documents,
      maintenance: maintenance ?? this.maintenance,
      trips: trips ?? this.trips,
      previousDrivers: previousDrivers ?? this.previousDrivers,
      notes: notes ?? this.notes,
    );
  }
}

class VehicleGalleryImage {
  final String label;
  final String angle;
  final String condition;

  const VehicleGalleryImage({
    required this.label,
    required this.angle,
    required this.condition,
  });
}

class VehicleDocument {
  final String title;
  final String number;
  final String expirationDate;
  final String previewLabel;
  final bool expired;

  const VehicleDocument({
    required this.title,
    required this.number,
    required this.expirationDate,
    required this.previewLabel,
    required this.expired,
  });
}

class VehicleMaintenance {
  final String title;
  final String date;
  final String status;
  final String notes;

  const VehicleMaintenance({
    required this.title,
    required this.date,
    required this.status,
    required this.notes,
  });
}

class VehicleTrip {
  final String tripNumber;
  final String route;
  final String driver;
  final String status;

  const VehicleTrip({
    required this.tripNumber,
    required this.route,
    required this.driver,
    required this.status,
  });
}

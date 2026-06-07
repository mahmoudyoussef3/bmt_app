enum DriverStatus {
  active('نشط'),
  suspended('موقوف'),
  onLeave('في إجازة'),
  pendingDocuments('بانتظار مراجعة المستندات');

  final String label;

  const DriverStatus(this.label);
}

class Driver {
  final String id;
  final String name;
  final String phone;
  final String nationalId;
  final String email;
  final String address;
  final String avatarInitials;
  final String currentVehicle;
  final String currentRoute;
  final int totalTrips;
  final int todayTrips;
  final int monthlyTrips;
  final int totalPassengers;
  final double rating;
  final DriverStatus status;
  final String assignedAt;
  final String licenseNumber;
  final String licenseExpiry;
  final List<DriverDocument> documents;
  final List<DriverReview> reviews;
  final List<DriverComplaint> complaints;
  final List<String> notes;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.email,
    required this.address,
    required this.avatarInitials,
    required this.currentVehicle,
    required this.currentRoute,
    required this.totalTrips,
    required this.todayTrips,
    required this.monthlyTrips,
    required this.totalPassengers,
    required this.rating,
    required this.status,
    required this.assignedAt,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.documents,
    required this.reviews,
    required this.complaints,
    required this.notes,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? nationalId,
    String? email,
    String? address,
    String? avatarInitials,
    String? currentVehicle,
    String? currentRoute,
    int? totalTrips,
    int? todayTrips,
    int? monthlyTrips,
    int? totalPassengers,
    double? rating,
    DriverStatus? status,
    String? assignedAt,
    String? licenseNumber,
    String? licenseExpiry,
    List<DriverDocument>? documents,
    List<DriverReview>? reviews,
    List<DriverComplaint>? complaints,
    List<String>? notes,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      email: email ?? this.email,
      address: address ?? this.address,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      currentVehicle: currentVehicle ?? this.currentVehicle,
      currentRoute: currentRoute ?? this.currentRoute,
      totalTrips: totalTrips ?? this.totalTrips,
      todayTrips: todayTrips ?? this.todayTrips,
      monthlyTrips: monthlyTrips ?? this.monthlyTrips,
      totalPassengers: totalPassengers ?? this.totalPassengers,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      documents: documents ?? this.documents,
      reviews: reviews ?? this.reviews,
      complaints: complaints ?? this.complaints,
      notes: notes ?? this.notes,
    );
  }
}

class DriverDocument {
  final String title;
  final String number;
  final String status;
  final String updatedAt;

  const DriverDocument({
    required this.title,
    required this.number,
    required this.status,
    required this.updatedAt,
  });
}

class DriverReview {
  final String passengerName;
  final double rating;
  final String comment;

  const DriverReview({
    required this.passengerName,
    required this.rating,
    required this.comment,
  });
}

class DriverComplaint {
  final String id;
  final String passengerName;
  final String status;
  final String summary;

  const DriverComplaint({
    required this.id,
    required this.passengerName,
    required this.status,
    required this.summary,
  });
}

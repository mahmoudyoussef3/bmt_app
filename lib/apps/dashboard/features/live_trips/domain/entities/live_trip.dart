enum LiveTripStatus {
  notStarted,
  preparing,
  inProgress,
  paused,
  completed,
  cancelled,
}

enum LiveTripHealth { normal, delayed, warning, critical }

enum LivePointStatus { pending, current, arrived, completed, skipped }

enum LiveTripAlertSeverity { info, warning, critical }

enum LiveTripAlertType {
  delay,
  driverOffline,
  passengerMissing,
  routeDeviation,
  vehicleIssue,
  overCapacity,
  emergency,
}

extension LiveTripStatusX on LiveTripStatus {
  String get label => switch (this) {
    LiveTripStatus.notStarted => 'لم تبدأ',
    LiveTripStatus.preparing => 'جاري التجهيز',
    LiveTripStatus.inProgress => 'قيد التنفيذ',
    LiveTripStatus.paused => 'متوقفة مؤقتًا',
    LiveTripStatus.completed => 'مكتملة',
    LiveTripStatus.cancelled => 'ملغية',
  };
}

extension LiveTripHealthX on LiveTripHealth {
  String get label => switch (this) {
    LiveTripHealth.normal => 'طبيعية',
    LiveTripHealth.delayed => 'متأخرة',
    LiveTripHealth.warning => 'تحذير',
    LiveTripHealth.critical => 'حرجة',
  };
}

extension LivePointStatusX on LivePointStatus {
  String get label => switch (this) {
    LivePointStatus.pending => 'لم تصل بعد',
    LivePointStatus.current => 'المحطة الحالية',
    LivePointStatus.arrived => 'وصلت',
    LivePointStatus.completed => 'تمت',
    LivePointStatus.skipped => 'تم التخطي',
  };
}

extension LiveTripAlertSeverityX on LiveTripAlertSeverity {
  String get label => switch (this) {
    LiveTripAlertSeverity.info => 'معلومة',
    LiveTripAlertSeverity.warning => 'تحذير',
    LiveTripAlertSeverity.critical => 'حرج',
  };
}

extension LiveTripAlertTypeX on LiveTripAlertType {
  String get label => switch (this) {
    LiveTripAlertType.delay => 'تأخير',
    LiveTripAlertType.driverOffline => 'السائق غير متصل',
    LiveTripAlertType.passengerMissing => 'راكب متأخر',
    LiveTripAlertType.routeDeviation => 'خروج عن المسار',
    LiveTripAlertType.vehicleIssue => 'مشكلة في المركبة',
    LiveTripAlertType.overCapacity => 'تجاوز السعة',
    LiveTripAlertType.emergency => 'طوارئ',
  };
}

class VehiclePosition {
  const VehiclePosition({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed; // m/s from Geolocator
  final double? accuracy; // horizontal accuracy radius in meters
  final DateTime updatedAt;

  bool get isMoving => speed != null && speed! > 0.5;
  bool get isStale => DateTime.now().difference(updatedAt).inMinutes > 2;
}

class LiveRoutePoint {
  const LiveRoutePoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    required this.status,
    required this.waitingPassengersCount,
    required this.boardedPassengersCount,
    this.plannedArrivalTime,
    this.actualArrivalTime,
    this.estimatedArrival,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final DateTime? plannedArrivalTime;
  final DateTime? actualArrivalTime;

  /// Live ETA from the route progress engine; null once visited or when no
  /// estimate is possible.
  final DateTime? estimatedArrival;
  final LivePointStatus status;
  final int waitingPassengersCount;
  final int boardedPassengersCount;

  LiveRoutePoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? order,
    DateTime? plannedArrivalTime,
    DateTime? actualArrivalTime,
    DateTime? estimatedArrival,
    bool clearEstimatedArrival = false,
    LivePointStatus? status,
    int? waitingPassengersCount,
    int? boardedPassengersCount,
  }) {
    return LiveRoutePoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      order: order ?? this.order,
      plannedArrivalTime: plannedArrivalTime ?? this.plannedArrivalTime,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      estimatedArrival: clearEstimatedArrival
          ? null
          : estimatedArrival ?? this.estimatedArrival,
      status: status ?? this.status,
      waitingPassengersCount:
          waitingPassengersCount ?? this.waitingPassengersCount,
      boardedPassengersCount:
          boardedPassengersCount ?? this.boardedPassengersCount,
    );
  }
}

class LiveTripAlert {
  const LiveTripAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.resolved,
  });

  final String id;
  final LiveTripAlertType type;
  final LiveTripAlertSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool resolved;

  LiveTripAlert copyWith({
    String? id,
    LiveTripAlertType? type,
    LiveTripAlertSeverity? severity,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? resolved,
  }) {
    return LiveTripAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      resolved: resolved ?? this.resolved,
    );
  }
}

class LivePassengerCheckin {
  const LivePassengerCheckin({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickupPointName,
    required this.checkedIn,
    this.checkedInAt,
  });

  final String id;
  final String passengerName;
  final String passengerPhone;
  final String pickupPointName;
  final bool checkedIn;
  final DateTime? checkedInAt;

  LivePassengerCheckin copyWith({
    String? id,
    String? passengerName,
    String? passengerPhone,
    String? pickupPointName,
    bool? checkedIn,
    DateTime? checkedInAt,
  }) {
    return LivePassengerCheckin(
      id: id ?? this.id,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      pickupPointName: pickupPointName ?? this.pickupPointName,
      checkedIn: checkedIn ?? this.checkedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }
}

class LiveTrip {
  const LiveTrip({
    required this.id,
    required this.tripCode,
    required this.routeId,
    required this.routeName,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.status,
    required this.health,
    required this.passengersCount,
    required this.checkedInPassengersCount,
    required this.missingPassengersCount,
    required this.progressPercent,
    required this.scheduledStartTime,
    required this.routePoints,
    required this.currentPointIndex,
    required this.alerts,
    required this.passengers,
    this.actualStartTime,
    this.expectedArrivalTime,
    this.vehiclePosition,
  });

  final String id;
  final String tripCode;
  final String routeId;
  final String routeName;

  final String driverId;
  final String driverName;
  final String driverPhone;

  final String vehicleId;
  final String vehiclePlate;
  final String vehicleType;

  final LiveTripStatus status;
  final LiveTripHealth health;

  final int passengersCount;
  final int checkedInPassengersCount;
  final int missingPassengersCount;
  final int progressPercent;

  final DateTime scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? expectedArrivalTime;

  final List<LiveRoutePoint> routePoints;
  final int currentPointIndex;

  final List<LiveTripAlert> alerts;
  final List<LivePassengerCheckin> passengers;
  final VehiclePosition? vehiclePosition;

  LiveRoutePoint? get currentPoint {
    if (routePoints.isEmpty) return null;
    final index = currentPointIndex.clamp(0, routePoints.length - 1);
    return routePoints[index];
  }

  LiveRoutePoint? get nextPoint {
    if (routePoints.isEmpty || currentPointIndex + 1 >= routePoints.length) {
      return null;
    }
    return routePoints[currentPointIndex + 1];
  }

  int get unresolvedAlertsCount =>
      alerts.where((alert) => !alert.resolved).length;

  int get criticalAlertsCount => alerts
      .where(
        (alert) =>
            !alert.resolved && alert.severity == LiveTripAlertSeverity.critical,
      )
      .length;

  LiveTrip copyWith({
    String? id,
    String? tripCode,
    String? routeId,
    String? routeName,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleId,
    String? vehiclePlate,
    String? vehicleType,
    LiveTripStatus? status,
    LiveTripHealth? health,
    int? passengersCount,
    int? checkedInPassengersCount,
    int? missingPassengersCount,
    int? progressPercent,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? expectedArrivalTime,
    List<LiveRoutePoint>? routePoints,
    int? currentPointIndex,
    List<LiveTripAlert>? alerts,
    List<LivePassengerCheckin>? passengers,
    VehiclePosition? vehiclePosition,
    bool clearVehiclePosition = false,
  }) {
    return LiveTrip(
      id: id ?? this.id,
      tripCode: tripCode ?? this.tripCode,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
      health: health ?? this.health,
      passengersCount: passengersCount ?? this.passengersCount,
      checkedInPassengersCount:
          checkedInPassengersCount ?? this.checkedInPassengersCount,
      missingPassengersCount:
          missingPassengersCount ?? this.missingPassengersCount,
      progressPercent: progressPercent ?? this.progressPercent,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      expectedArrivalTime: expectedArrivalTime ?? this.expectedArrivalTime,
      routePoints: routePoints ?? this.routePoints,
      currentPointIndex: currentPointIndex ?? this.currentPointIndex,
      alerts: alerts ?? this.alerts,
      passengers: passengers ?? this.passengers,
      vehiclePosition: clearVehiclePosition
          ? null
          : vehiclePosition ?? this.vehiclePosition,
    );
  }
}

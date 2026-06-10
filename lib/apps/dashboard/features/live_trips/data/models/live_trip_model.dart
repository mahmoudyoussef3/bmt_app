import '../../domain/entities/live_trip.dart';

class LiveRoutePointModel extends LiveRoutePoint {
  const LiveRoutePointModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.order,
    required super.status,
    required super.waitingPassengersCount,
    required super.boardedPassengersCount,
    super.plannedArrivalTime,
    super.actualArrivalTime,
  });

  factory LiveRoutePointModel.fromJson(Map<String, dynamic> json) {
    return LiveRoutePointModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      order: json['order'] as int,
      status: LivePointStatus.values.byName(json['status'].toString()),
      waitingPassengersCount: json['waitingPassengersCount'] as int,
      boardedPassengersCount: json['boardedPassengersCount'] as int,
      plannedArrivalTime: json['plannedArrivalTime'] == null
          ? null
          : DateTime.parse(json['plannedArrivalTime'].toString()),
      actualArrivalTime: json['actualArrivalTime'] == null
          ? null
          : DateTime.parse(json['actualArrivalTime'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'order': order,
        'status': status.name,
        'waitingPassengersCount': waitingPassengersCount,
        'boardedPassengersCount': boardedPassengersCount,
        'plannedArrivalTime': plannedArrivalTime?.toIso8601String(),
        'actualArrivalTime': actualArrivalTime?.toIso8601String(),
      };

  factory LiveRoutePointModel.fromEntity(LiveRoutePoint entity) {
    return LiveRoutePointModel(
      id: entity.id,
      name: entity.name,
      latitude: entity.latitude,
      longitude: entity.longitude,
      order: entity.order,
      status: entity.status,
      waitingPassengersCount: entity.waitingPassengersCount,
      boardedPassengersCount: entity.boardedPassengersCount,
      plannedArrivalTime: entity.plannedArrivalTime,
      actualArrivalTime: entity.actualArrivalTime,
    );
  }
}

class LiveTripAlertModel extends LiveTripAlert {
  const LiveTripAlertModel({
    required super.id,
    required super.type,
    required super.severity,
    required super.title,
    required super.message,
    required super.createdAt,
    required super.resolved,
  });

  factory LiveTripAlertModel.fromJson(Map<String, dynamic> json) {
    return LiveTripAlertModel(
      id: json['id'].toString(),
      type: LiveTripAlertType.values.byName(json['type'].toString()),
      severity:
          LiveTripAlertSeverity.values.byName(json['severity'].toString()),
      title: json['title'].toString(),
      message: json['message'].toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      resolved: json['resolved'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'severity': severity.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'resolved': resolved,
      };

  factory LiveTripAlertModel.fromEntity(LiveTripAlert entity) {
    return LiveTripAlertModel(
      id: entity.id,
      type: entity.type,
      severity: entity.severity,
      title: entity.title,
      message: entity.message,
      createdAt: entity.createdAt,
      resolved: entity.resolved,
    );
  }
}

class LivePassengerCheckinModel extends LivePassengerCheckin {
  const LivePassengerCheckinModel({
    required super.id,
    required super.passengerName,
    required super.passengerPhone,
    required super.pickupPointName,
    required super.checkedIn,
    super.checkedInAt,
  });

  factory LivePassengerCheckinModel.fromJson(Map<String, dynamic> json) {
    return LivePassengerCheckinModel(
      id: json['id'].toString(),
      passengerName: json['passengerName'].toString(),
      passengerPhone: json['passengerPhone'].toString(),
      pickupPointName: json['pickupPointName'].toString(),
      checkedIn: json['checkedIn'] as bool,
      checkedInAt: json['checkedInAt'] == null
          ? null
          : DateTime.parse(json['checkedInAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'passengerName': passengerName,
        'passengerPhone': passengerPhone,
        'pickupPointName': pickupPointName,
        'checkedIn': checkedIn,
        'checkedInAt': checkedInAt?.toIso8601String(),
      };

  factory LivePassengerCheckinModel.fromEntity(LivePassengerCheckin entity) {
    return LivePassengerCheckinModel(
      id: entity.id,
      passengerName: entity.passengerName,
      passengerPhone: entity.passengerPhone,
      pickupPointName: entity.pickupPointName,
      checkedIn: entity.checkedIn,
      checkedInAt: entity.checkedInAt,
    );
  }
}

class LiveTripModel extends LiveTrip {
  const LiveTripModel({
    required super.id,
    required super.tripCode,
    required super.routeId,
    required super.routeName,
    required super.driverId,
    required super.driverName,
    required super.driverPhone,
    required super.vehicleId,
    required super.vehiclePlate,
    required super.vehicleType,
    required super.status,
    required super.health,
    required super.passengersCount,
    required super.checkedInPassengersCount,
    required super.missingPassengersCount,
    required super.progressPercent,
    required super.scheduledStartTime,
    required super.routePoints,
    required super.currentPointIndex,
    required super.alerts,
    required super.passengers,
    super.actualStartTime,
    super.expectedArrivalTime,
  });

  factory LiveTripModel.fromJson(Map<String, dynamic> json) {
    return LiveTripModel(
      id: json['id'].toString(),
      tripCode: json['tripCode'].toString(),
      routeId: json['routeId'].toString(),
      routeName: json['routeName'].toString(),
      driverId: json['driverId'].toString(),
      driverName: json['driverName'].toString(),
      driverPhone: json['driverPhone'].toString(),
      vehicleId: json['vehicleId'].toString(),
      vehiclePlate: json['vehiclePlate'].toString(),
      vehicleType: json['vehicleType'].toString(),
      status: LiveTripStatus.values.byName(json['status'].toString()),
      health: LiveTripHealth.values.byName(json['health'].toString()),
      passengersCount: json['passengersCount'] as int,
      checkedInPassengersCount: json['checkedInPassengersCount'] as int,
      missingPassengersCount: json['missingPassengersCount'] as int,
      progressPercent: json['progressPercent'] as int,
      scheduledStartTime: DateTime.parse(json['scheduledStartTime'].toString()),
      actualStartTime: json['actualStartTime'] == null
          ? null
          : DateTime.parse(json['actualStartTime'].toString()),
      expectedArrivalTime: json['expectedArrivalTime'] == null
          ? null
          : DateTime.parse(json['expectedArrivalTime'].toString()),
      routePoints: (json['routePoints'] as List)
          .map((e) => LiveRoutePointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPointIndex: json['currentPointIndex'] as int,
      alerts: (json['alerts'] as List)
          .map((e) => LiveTripAlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      passengers: (json['passengers'] as List)
          .map((e) =>
              LivePassengerCheckinModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripCode': tripCode,
        'routeId': routeId,
        'routeName': routeName,
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'vehicleId': vehicleId,
        'vehiclePlate': vehiclePlate,
        'vehicleType': vehicleType,
        'status': status.name,
        'health': health.name,
        'passengersCount': passengersCount,
        'checkedInPassengersCount': checkedInPassengersCount,
        'missingPassengersCount': missingPassengersCount,
        'progressPercent': progressPercent,
        'scheduledStartTime': scheduledStartTime.toIso8601String(),
        'actualStartTime': actualStartTime?.toIso8601String(),
        'expectedArrivalTime': expectedArrivalTime?.toIso8601String(),
        'routePoints': routePoints
            .map((e) => LiveRoutePointModel.fromEntity(e).toJson())
            .toList(),
        'currentPointIndex': currentPointIndex,
        'alerts':
            alerts.map((e) => LiveTripAlertModel.fromEntity(e).toJson()).toList(),
        'passengers': passengers
            .map((e) => LivePassengerCheckinModel.fromEntity(e).toJson())
            .toList(),
      };

  factory LiveTripModel.fromEntity(LiveTrip entity) {
    return LiveTripModel(
      id: entity.id,
      tripCode: entity.tripCode,
      routeId: entity.routeId,
      routeName: entity.routeName,
      driverId: entity.driverId,
      driverName: entity.driverName,
      driverPhone: entity.driverPhone,
      vehicleId: entity.vehicleId,
      vehiclePlate: entity.vehiclePlate,
      vehicleType: entity.vehicleType,
      status: entity.status,
      health: entity.health,
      passengersCount: entity.passengersCount,
      checkedInPassengersCount: entity.checkedInPassengersCount,
      missingPassengersCount: entity.missingPassengersCount,
      progressPercent: entity.progressPercent,
      scheduledStartTime: entity.scheduledStartTime,
      actualStartTime: entity.actualStartTime,
      expectedArrivalTime: entity.expectedArrivalTime,
      routePoints: List<LiveRoutePoint>.from(entity.routePoints),
      currentPointIndex: entity.currentPointIndex,
      alerts: List<LiveTripAlert>.from(entity.alerts),
      passengers: List<LivePassengerCheckin>.from(entity.passengers),
    );
  }
}

import 'package:bmt_app/core/tracking/progress/route_stop.dart';

import '../../domain/entities/tracking_trip.dart';

class TrackingPointModel {
  const TrackingPointModel({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.heading,
    this.speed,
    this.accuracy,
  });

  factory TrackingPointModel.fromLiveLocationRow(Map<String, dynamic> row) {
    return TrackingPointModel(
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      recordedAt: row['recorded_at'] != null
          ? DateTime.tryParse(row['recorded_at'].toString())?.toLocal()
          : null,
      heading: (row['heading'] as num?)?.toDouble(),
      speed: (row['speed'] as num?)?.toDouble(),
      accuracy: (row['accuracy'] as num?)?.toDouble(),
    );
  }

  final double latitude;
  final double longitude;
  final DateTime? recordedAt;
  final double? heading;
  final double? speed;
  final double? accuracy;

  TrackingPoint toEntity() => TrackingPoint(
    latitude: latitude,
    longitude: longitude,
    recordedAt: recordedAt,
    heading: heading,
    speed: speed,
    accuracy: accuracy,
  );
}

class TrackingTripDataModel {
  const TrackingTripDataModel({
    required this.routePoints,
    required this.timelineSteps,
    required this.stops,
    required this.tripState,
    this.routeStops = const [],
    this.arrivalEventCount = 0,
    this.passengerPickupName,
    this.passengerDropoffName,
    this.passengerStatus,
    this.tripId,
    this.bookingId,
    this.routeName,
    this.pickupName,
    this.destinationName,
    this.departureAt,
    this.arrivalAt,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.vehicleName,
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleLatitude,
    this.vehicleLongitude,
    this.vehicleHeading,
    this.vehicleSpeed,
    this.vehicleAccuracy,
    this.vehicleLocationAt,
  });

  final List<TrackingPointModel> routePoints;
  final List<String> timelineSteps;
  final List<String> stops;
  final TrackingTripState tripState;
  final List<RouteStop> routeStops;
  final int arrivalEventCount;
  final String? passengerPickupName;
  final String? passengerDropoffName;
  final String? passengerStatus;
  final String? tripId;
  final String? bookingId;
  final String? routeName;
  final String? pickupName;
  final String? destinationName;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? vehicleName;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? vehicleLatitude;
  final double? vehicleLongitude;
  final double? vehicleHeading;
  final double? vehicleSpeed;
  final double? vehicleAccuracy;
  final DateTime? vehicleLocationAt;

  TrackingTripData toEntity() {
    return TrackingTripData(
      routePoints: routePoints.map((p) => p.toEntity()).toList(),
      timelineSteps: timelineSteps,
      stops: stops,
      tripState: tripState,
      routeStops: routeStops,
      arrivalEventCount: arrivalEventCount,
      passengerPickupName: passengerPickupName,
      passengerDropoffName: passengerDropoffName,
      passengerStatus: passengerStatus,
      tripId: tripId,
      bookingId: bookingId,
      routeName: routeName,
      pickupName: pickupName,
      destinationName: destinationName,
      departureAt: departureAt,
      arrivalAt: arrivalAt,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      vehicleLatitude: vehicleLatitude,
      vehicleLongitude: vehicleLongitude,
      vehicleHeading: vehicleHeading,
      vehicleSpeed: vehicleSpeed,
      vehicleAccuracy: vehicleAccuracy,
      vehicleLocationAt: vehicleLocationAt,
    );
  }
}

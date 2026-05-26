part of 'tracking_cubit.dart';

class TrackingState {
  final Trip? trip;
  final Vehicle? vehicle;
  final String? driverName;
  final String? driverPhone;
  final DateTime? eta;
  final double vehicleLat;
  final double vehicleLng;

  const TrackingState({
    this.trip,
    this.vehicle,
    this.driverName,
    this.driverPhone,
    this.eta,
    this.vehicleLat = 30.0,
    this.vehicleLng = 31.0,
  });

  TrackingState copyWith({
    Trip? trip,
    Vehicle? vehicle,
    String? driverName,
    String? driverPhone,
    DateTime? eta,
    double? vehicleLat,
    double? vehicleLng,
  }) {
    return TrackingState(
      trip: trip ?? this.trip,
      vehicle: vehicle ?? this.vehicle,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      eta: eta ?? this.eta,
      vehicleLat: vehicleLat ?? this.vehicleLat,
      vehicleLng: vehicleLng ?? this.vehicleLng,
    );
  }
}

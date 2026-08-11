import 'package:geolocator/geolocator.dart';

import '../../domain/entities/captain_location_fix.dart';
import '../../domain/entities/location_gate.dart';

class CaptainLocationStreamDatasource {
  const CaptainLocationStreamDatasource();

  static const int _distanceFilterMeters = 8;

  Future<LocationGate> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationGate.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.denied => LocationGate.denied,
      LocationPermission.deniedForever => LocationGate.deniedForever,
      _ => LocationGate.ready,
    };
  }

  Stream<CaptainLocationFix> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
      ),
    ).map(_toFix);
  }

  CaptainLocationFix _toFix(Position position) => CaptainLocationFix(
    latitude: position.latitude,
    longitude: position.longitude,
    recordedAt: position.timestamp,
    heading: position.heading < 0 ? null : position.heading,
    speed: position.speed < 0 ? null : position.speed,
    accuracy: position.accuracy,
  );
}

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/captain_location_fix.dart';
import '../../domain/entities/location_gate.dart';

/// Reads the device's own positioning sensor for the trip map.
///
/// A distance-filtered stream rather than a timer: the OS only wakes the app
/// when the vehicle has actually moved [_distanceFilterMeters], which keeps the
/// map smooth on the road and idle in a queue without a polling loop of our
/// own. Foreground only — this stream lives exactly as long as the map screen,
/// and the app claims no background location.
class CaptainLocationStreamDatasource {
  const CaptainLocationStreamDatasource();

  /// Meters of movement between emitted fixes. Small enough that the marker
  /// glides, large enough that a parked bus doesn't stream jitter.
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
    // Geolocator reports -1 when the sensor has no heading/speed; normalise to
    // null so the marker doesn't rotate to due north on a stationary fix.
    heading: position.heading < 0 ? null : position.heading,
    speed: position.speed < 0 ? null : position.speed,
    accuracy: position.accuracy,
  );
}

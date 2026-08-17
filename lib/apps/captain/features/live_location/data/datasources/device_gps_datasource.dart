import 'package:geolocator/geolocator.dart';

import 'package:bmt_app/core/tracking/live_tracking_config.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

/// The device's GPS, as a stream of raw fixes.
///
/// Deliberately separate from [SupabaseLocationDatasource]: acquiring a position
/// and writing one are two different jobs, and until they were split there was
/// nothing to throttle — the publisher could only ask for a fix at the moment it
/// wanted to write one. Now the sensor produces at its own rate and the pipeline
/// decides what reaches the database.
///
/// Raw on purpose. Nothing here judges a fix; validation is
/// `ValidFixFilter`'s job, one stage further along.
class DeviceGpsDatasource {
  const DeviceGpsDatasource({LiveTrackingConfig config = kLiveTrackingConfig})
    : _config = config;

  final LiveTrackingConfig _config;

  /// Positions as the device reports them.
  ///
  /// `distanceFilter` is what keeps a stationary vehicle from spending battery
  /// and writes on jitter: standing at a station produces no events at all. The
  /// cost of that silence is that "parked" and "GPS died" look identical, which
  /// is why the publisher carries a heartbeat.
  Stream<VehicleFix> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _config.distanceFilterMeters.round(),
      ),
    ).map(toFix);
  }

  /// A single fix, for the manual "send my location now" button and the
  /// heartbeat — both of which want an answer rather than a subscription.
  Future<VehicleFix> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return toFix(position);
  }

  /// Geolocator reports "no reading" as a negative number; the domain says so
  /// with null instead.
  static VehicleFix toFix(Position position) => VehicleFix(
    latitude: position.latitude,
    longitude: position.longitude,
    recordedAt: position.timestamp,
    headingDegrees: position.heading < 0 ? null : position.heading,
    speedMetersPerSecond: position.speed < 0 ? null : position.speed,
    accuracyMeters: position.accuracy,
  );

  /// Throws with a captain-facing reason when the platform will not give us a
  /// position at all.
  Future<void> ensureAvailable() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('فعّل خدمة الموقع في الهاتف ثم حاول مرة أخرى.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('يلزم السماح بالوصول للموقع لإرسال موقعك الحالي.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق.',
      );
    }
  }
}

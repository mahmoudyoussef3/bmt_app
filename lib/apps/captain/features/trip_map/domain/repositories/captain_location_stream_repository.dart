import '../entities/captain_location_fix.dart';
import '../entities/location_gate.dart';

/// Access to the captain device's own live position, for the trip map.
///
/// Distinct from the live-location repository that *publishes* fixes to the
/// backend: this one only *reads* the local sensor to draw the captain's own
/// vehicle, and never writes anything.
abstract class CaptainLocationStreamRepository {
  /// Checks the location service and permission, requesting permission when it
  /// has not been decided yet. Call before [watchPosition].
  Future<LocationGate> ensureReady();

  /// A stream of the device's position while the map is open. Emits a fix each
  /// time the device moves past the configured distance filter.
  Stream<CaptainLocationFix> watchPosition();
}

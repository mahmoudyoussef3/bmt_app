import '../entities/captain_location_fix.dart';
import '../entities/location_gate.dart';

abstract class CaptainLocationStreamRepository {
  Future<LocationGate> ensureReady();

  Stream<CaptainLocationFix> watchPosition();
}

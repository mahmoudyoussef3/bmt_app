import '../models/driver_position.dart';

abstract class DriverStreamRepository {
  /// Subscribe to driver position/status updates
  Stream<DriverPosition> subscribeDriverUpdates();
}

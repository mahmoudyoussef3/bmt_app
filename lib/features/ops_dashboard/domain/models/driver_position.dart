import 'position.dart';
import 'driver.dart';

class DriverPosition {
  final String driverId;
  final Position position;
  final DriverStatus status;

  DriverPosition({required this.driverId, required this.position, this.status = DriverStatus.offline});
}

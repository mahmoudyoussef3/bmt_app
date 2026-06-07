import '../entities/vehicle.dart';

abstract class VehiclesRepository {
  Future<List<Vehicle>> getVehicles();
  Future<Vehicle> createVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicleStatus(String vehicleId, VehicleStatus status);
  Future<Vehicle> renewDocument(String vehicleId, String documentTitle);
}

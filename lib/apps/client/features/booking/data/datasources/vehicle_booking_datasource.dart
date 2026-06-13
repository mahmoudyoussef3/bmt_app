import '../models/vehicle_detail_model.dart';

abstract class VehicleBookingDatasource {
  Future<List<VehicleDetailModel>> getVehicles();
  Future<VehicleDetailModel?> getVehicleById(String id);
}

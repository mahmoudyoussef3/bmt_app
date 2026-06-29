import '../models/vehicle_detail_model.dart';

abstract class VehicleBookingDatasource {
  Future<List<VehicleDetailModel>> getVehicles({String? routeId});
  Future<VehicleDetailModel?> getVehicleById(String id);
}

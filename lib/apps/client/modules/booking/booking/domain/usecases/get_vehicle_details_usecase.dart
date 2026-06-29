import '../entities/vehicle_detail.dart';
import '../repositories/booking_repository.dart';

class GetVehicleDetailsUseCase {
  const GetVehicleDetailsUseCase(this._repository);

  final BookingRepository _repository;

  Future<VehicleDetailData?> call(String id) {
    return _repository.getVehicleById(id);
  }
}

import '../entities/vehicle_detail.dart';
import '../repositories/booking_repository.dart';

class GetVehiclesUseCase {
  const GetVehiclesUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<VehicleDetailData>> call() {
    return _repository.getVehicles();
  }
}

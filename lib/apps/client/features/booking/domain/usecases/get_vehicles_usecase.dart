import '../entities/vehicle_detail.dart';
import '../repositories/booking_repository.dart';

class GetVehiclesUseCase {
  const GetVehiclesUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<VehicleDetailData>> call({String? routeId}) {
    return _repository.getVehicles(routeId: routeId);
  }
}

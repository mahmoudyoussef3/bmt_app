import '../entities/office_trip.dart';
import '../repositories/offices_repository.dart';

class GetOfficeTripsUseCase {
  const GetOfficeTripsUseCase(this._repository);

  final OfficesRepository _repository;

  Future<List<OfficeTrip>> call(String officeId) =>
      _repository.getOfficeTrips(officeId);
}

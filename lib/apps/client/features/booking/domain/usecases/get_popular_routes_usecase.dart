import '../entities/booking_option.dart';
import '../repositories/booking_repository.dart';

class GetPopularRoutesUseCase {
  const GetPopularRoutesUseCase(this._repository);

  final BookingRepository _repository;

  Future<List<PopularRouteListData>> call() {
    return _repository.getPopularRoutes();
  }
}

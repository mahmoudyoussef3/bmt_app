import '../entities/search_options.dart';
import '../repositories/booking_repository.dart';

class GetSearchOptionsUseCase {
  const GetSearchOptionsUseCase(this._repository);

  final BookingRepository _repository;

  Future<TripSearchOptions> call() => _repository.getSearchOptions();
}

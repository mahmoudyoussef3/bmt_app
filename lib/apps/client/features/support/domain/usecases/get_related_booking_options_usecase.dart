import '../repositories/support_repository.dart';
import '../entities/related_booking_option.dart';

class GetRelatedBookingOptionsUseCase {
  final SupportRepository _repository;

  const GetRelatedBookingOptionsUseCase(this._repository);

  Future<List<RelatedBookingOption>> call() {
    return _repository.getRelatedBookingOptions();
  }
}

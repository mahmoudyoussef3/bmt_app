import '../repositories/tracking_repository.dart';

/// The rider's own "نعم، صعدت".
///
/// Not a captain action delegated to the rider: it is the rider's statement
/// about themselves, and it is the thing that satisfies their station's boarding
/// requirement and ends their own live-vehicle tracking.
class ConfirmBoardingUseCase {
  const ConfirmBoardingUseCase(this._repository);

  final TrackingRepository _repository;

  Future<void> call(String bookingId) => _repository.confirmBoarding(bookingId);
}

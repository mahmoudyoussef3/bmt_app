import '../entities/booking_payment_verification.dart';
import '../repositories/booking_payment_verification_repository.dart';

class GetBookingPaymentVerificationsUseCase {
  final BookingPaymentVerificationRepository _repository;

  const GetBookingPaymentVerificationsUseCase(this._repository);

  Future<List<BookingPaymentVerification>> call() {
    return _repository.getQueue();
  }
}

import '../entities/booking_payment_verification.dart';
import '../repositories/booking_payment_verification_repository.dart';

class RejectBookingPaymentUseCase {
  final BookingPaymentVerificationRepository _repository;

  const RejectBookingPaymentUseCase(this._repository);

  Future<BookingPaymentVerification> call(String verificationId, String note) {
    return _repository.reject(verificationId, note);
  }
}

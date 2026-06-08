import '../entities/booking_payment_verification.dart';
import '../repositories/booking_payment_verification_repository.dart';

class ApproveBookingPaymentUseCase {
  final BookingPaymentVerificationRepository _repository;

  const ApproveBookingPaymentUseCase(this._repository);

  Future<BookingPaymentVerification> call(String verificationId, String note) {
    return _repository.approve(verificationId, note);
  }
}

import '../entities/booking_payment_verification.dart';
import '../repositories/booking_payment_verification_repository.dart';

class RequestBookingPaymentReviewUseCase {
  final BookingPaymentVerificationRepository _repository;

  const RequestBookingPaymentReviewUseCase(this._repository);

  Future<BookingPaymentVerification> call(String verificationId, String note) {
    return _repository.requestReview(verificationId, note);
  }
}

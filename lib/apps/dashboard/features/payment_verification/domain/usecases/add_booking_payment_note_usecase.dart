import '../entities/booking_payment_verification.dart';
import '../repositories/booking_payment_verification_repository.dart';

class AddBookingPaymentNoteUseCase {
  final BookingPaymentVerificationRepository _repository;

  const AddBookingPaymentNoteUseCase(this._repository);

  Future<BookingPaymentVerification> call(String verificationId, String note) {
    return _repository.addNote(verificationId, note);
  }
}

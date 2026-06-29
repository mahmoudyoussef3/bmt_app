import '../entities/booking_payment_verification.dart';

abstract class BookingPaymentVerificationRepository {
  Future<List<BookingPaymentVerification>> getQueue();

  Future<BookingPaymentVerification> approve(
    String verificationId,
    String note,
  );

  Future<BookingPaymentVerification> reject(String verificationId, String note);

  Future<BookingPaymentVerification> requestReview(
    String verificationId,
    String note,
  );

  Future<BookingPaymentVerification> addNote(
    String verificationId,
    String note,
  );
}

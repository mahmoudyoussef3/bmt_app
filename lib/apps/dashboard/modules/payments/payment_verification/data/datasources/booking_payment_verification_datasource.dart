import '../models/booking_payment_verification_model.dart';

abstract class BookingPaymentVerificationDatasource {
  Future<List<BookingPaymentVerificationModel>> fetchQueue();

  Future<BookingPaymentVerificationModel> approve(
    String verificationId,
    String note,
  );

  Future<BookingPaymentVerificationModel> reject(
    String verificationId,
    String note,
  );

  Future<BookingPaymentVerificationModel> requestReview(
    String verificationId,
    String note,
  );

  Future<BookingPaymentVerificationModel> addNote(
    String verificationId,
    String note,
  );
}

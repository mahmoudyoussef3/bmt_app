import '../../domain/entities/finance_payment.dart';

abstract class PaymentsDatasource {
  Future<List<FinancePayment>> fetchPayments();

  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  );

  Future<FinancePayment> addNote(String paymentId, String note);

  Future<List<Map<String, dynamic>>> fetchAvailableTrips();

  Future<void> reassignBooking(String bookingId, String newTripId);
}

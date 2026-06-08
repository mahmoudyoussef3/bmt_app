import '../../domain/entities/booking_payment_verification.dart';

class BookingPaymentVerificationModel extends BookingPaymentVerification {
  const BookingPaymentVerificationModel({
    required super.id,
    required super.bookingId,
    required super.customer,
    required super.trip,
    required super.selectedSeat,
    required super.seatState,
    required super.amount,
    required super.method,
    required super.referenceNumber,
    required super.receiptTitle,
    required super.receiptMeta,
    required super.status,
    required super.notes,
    required super.history,
  });

  factory BookingPaymentVerificationModel.fromEntity(
    BookingPaymentVerification verification,
  ) {
    return BookingPaymentVerificationModel(
      id: verification.id,
      bookingId: verification.bookingId,
      customer: verification.customer,
      trip: verification.trip,
      selectedSeat: verification.selectedSeat,
      seatState: verification.seatState,
      amount: verification.amount,
      method: verification.method,
      referenceNumber: verification.referenceNumber,
      receiptTitle: verification.receiptTitle,
      receiptMeta: verification.receiptMeta,
      status: verification.status,
      notes: verification.notes,
      history: verification.history,
    );
  }
}

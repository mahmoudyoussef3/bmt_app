enum BookingVerificationStatus {
  pending('بانتظار التحقق'),
  approved('مقبول'),
  rejected('مرفوض'),
  reviewRequested('مراجعة مطلوبة');

  final String label;

  const BookingVerificationStatus(this.label);
}

enum VerificationPaymentMethod {
  card('بطاقة'),
  wallet('محفظة'),
  bankTransfer('تحويل بنكي'),
  cash('كاش');

  final String label;

  const VerificationPaymentMethod(this.label);
}

enum VerificationSeatState {
  temporaryReserved('حجز مؤقت'),
  permanentlyConfirmed('مؤكد نهائياً'),
  released('متاح مرة أخرى');

  final String label;

  const VerificationSeatState(this.label);
}

class BookingPaymentVerification {
  final String id;
  final String bookingId;
  final VerificationCustomer customer;
  final VerificationTrip trip;
  final String selectedSeat;
  final VerificationSeatState seatState;
  final String amount;
  final VerificationPaymentMethod method;
  final String referenceNumber;
  final String receiptTitle;
  final String receiptMeta;
  final String? receiptUrl;
  final BookingVerificationStatus status;
  final List<String> notes;
  final List<VerificationHistoryItem> history;

  const BookingPaymentVerification({
    required this.id,
    required this.bookingId,
    required this.customer,
    required this.trip,
    required this.selectedSeat,
    required this.seatState,
    required this.amount,
    required this.method,
    required this.referenceNumber,
    required this.receiptTitle,
    required this.receiptMeta,
    required this.status,
    required this.notes,
    required this.history,
    this.receiptUrl,
  });

  BookingPaymentVerification copyWith({
    VerificationSeatState? seatState,
    BookingVerificationStatus? status,
    List<String>? notes,
    List<VerificationHistoryItem>? history,
  }) {
    return BookingPaymentVerification(
      id: id,
      bookingId: bookingId,
      customer: customer,
      trip: trip,
      selectedSeat: selectedSeat,
      seatState: seatState ?? this.seatState,
      amount: amount,
      method: method,
      referenceNumber: referenceNumber,
      receiptTitle: receiptTitle,
      receiptMeta: receiptMeta,
      receiptUrl: receiptUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      history: history ?? this.history,
    );
  }
}

class VerificationCustomer {
  final String name;
  final String phone;
  final String email;
  final String profileStatus;

  const VerificationCustomer({
    required this.name,
    required this.phone,
    required this.email,
    required this.profileStatus,
  });
}

class VerificationTrip {
  final String tripId;
  final String route;
  final String date;
  final String time;
  final String vehicle;
  final String driver;

  const VerificationTrip({
    required this.tripId,
    required this.route,
    required this.date,
    required this.time,
    required this.vehicle,
    required this.driver,
  });
}

class VerificationHistoryItem {
  final String title;
  final String time;
  final String description;

  const VerificationHistoryItem({
    required this.title,
    required this.time,
    required this.description,
  });
}

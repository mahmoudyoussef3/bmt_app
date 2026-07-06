enum BookingStatus {
  draft('مسودة'),
  reserved('محجوز'),
  confirmed('مؤكد'),
  boarded('تم الصعود'),
  completed('مكتمل'),
  cancelled('ملغى');

  final String label;

  const BookingStatus(this.label);
}

enum PaymentStatus {
  pending('قيد الانتظار'),
  submitted('تم الرفع'),
  underReview('قيد المراجعة'),
  approved('مقبول'),
  rejected('مرفوض'),
  refunded('مسترد'),
  failed('فاشل');

  final String label;

  const PaymentStatus(this.label);
}

enum BookingPaymentMethod {
  instaPay('انستا باي'),
  vodafoneCash('فودافون كاش'),
  cash('نقدي'),
  card('بطاقة'),
  bankTransfer('تحويل بنكي');

  final String label;

  const BookingPaymentMethod(this.label);
}

/// One entry in a booking's lifecycle history, derived from real timestamps
/// on the row (creation, payment review outcome) — never fabricated.
class BookingTimelineEvent {
  final DateTime timestamp;
  final String action;
  final String? note;

  const BookingTimelineEvent({
    required this.timestamp,
    required this.action,
    this.note,
  });
}

/// Real trip context joined from `operation_trips` (route, driver, vehicle).
class BookingTripDetails {
  final String tripId;
  final String route;
  final String date;
  final String time;
  final String vehicle;
  final String driver;

  const BookingTripDetails({
    required this.tripId,
    required this.route,
    required this.date,
    required this.time,
    required this.vehicle,
    required this.driver,
  });

  static const empty = BookingTripDetails(
    tripId: '',
    route: '',
    date: '',
    time: '',
    vehicle: '',
    driver: '',
  );
}

/// A single operational booking, mapped 1:1 from a real `operation_bookings`
/// row and the entities it references (client, trip, package).
class OperationBooking {
  final String id;
  final String bookingNumber;
  final String clientId;
  final String passengerName;
  final String phone;
  final String route;
  final String tripTime;
  final String date;
  final String seat;
  final BookingPaymentMethod paymentMethod;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double paymentAmount;
  final String packageName;
  final String? receiptUrl;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final BookingTripDetails tripDetails;
  final List<String> notes;
  final List<BookingTimelineEvent> timeline;

  const OperationBooking({
    required this.id,
    required this.bookingNumber,
    required this.clientId,
    required this.passengerName,
    required this.phone,
    required this.route,
    required this.tripTime,
    required this.date,
    required this.seat,
    required this.paymentMethod,
    required this.status,
    required this.paymentStatus,
    required this.paymentAmount,
    required this.packageName,
    required this.createdAt,
    required this.tripDetails,
    required this.notes,
    required this.timeline,
    this.receiptUrl,
    this.rejectionReason,
    this.reviewedAt,
  });

  /// A payment awaiting a dashboard decision (the actionable review queue).
  bool get awaitingReview =>
      paymentStatus == PaymentStatus.submitted ||
      paymentStatus == PaymentStatus.underReview;

  bool get hasReceipt => (receiptUrl ?? '').isNotEmpty;

  String get amountLabel {
    final rounded = paymentAmount == paymentAmount.roundToDouble()
        ? paymentAmount.toStringAsFixed(0)
        : paymentAmount.toStringAsFixed(2);
    return '$rounded ج.م';
  }
}

enum BookingStatus {
  newRequest('طلب جديد'),
  paymentUploaded('تم رفع الإيصال'),
  underReview('قيد المراجعة'),
  approved('مقبول'),
  rejected('مرفوض'),
  requestReupload('طلب إعادة رفع'),
  confirmed('مؤكد المقعد'),
  cancelled('ملغى');

  final String label;

  const BookingStatus(this.label);
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

enum BookingPriority {
  normal('عادي'),
  urgent('مستعجل');

  final String label;

  const BookingPriority(this.label);
}

class BookingTimelineEvent {
  final DateTime timestamp;
  final String action;
  final String actor;
  final String? note;

  const BookingTimelineEvent({
    required this.timestamp,
    required this.action,
    required this.actor,
    this.note,
  });
}

class OperationBooking {
  final String id;
  final String passengerName;
  final String phone;
  final String route;
  final String tripTime;
  final String date;
  final String seat;
  final BookingPaymentMethod paymentMethod;
  final BookingStatus status;
  final BookingPriority priority;
  final String assignedTrip;
  final String? reviewerName;
  final String? rejectionReason;
  final DateTime createdAt;
  final BookingCustomerProfile customerProfile;
  final BookingTripDetails tripDetails;
  final BookingPaymentDetails paymentDetails;
  final List<String> attachments;
  final List<String> notes;
  final List<BookingTimelineEvent> timeline;

  const OperationBooking({
    required this.id,
    required this.passengerName,
    required this.phone,
    required this.route,
    required this.tripTime,
    required this.date,
    required this.seat,
    required this.paymentMethod,
    required this.status,
    required this.priority,
    required this.assignedTrip,
    required this.createdAt,
    required this.customerProfile,
    required this.tripDetails,
    required this.paymentDetails,
    required this.attachments,
    required this.notes,
    required this.timeline,
    this.reviewerName,
    this.rejectionReason,
  });

  OperationBooking copyWith({
    String? id,
    BookingStatus? status,
    BookingPriority? priority,
    String? assignedTrip,
    String? reviewerName,
    String? rejectionReason,
    List<BookingTimelineEvent>? timeline,
  }) {
    return OperationBooking(
      id: id ?? this.id,
      passengerName: passengerName,
      phone: phone,
      route: route,
      tripTime: tripTime,
      date: date,
      seat: seat,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTrip: assignedTrip ?? this.assignedTrip,
      createdAt: createdAt,
      customerProfile: customerProfile,
      tripDetails: tripDetails,
      paymentDetails: paymentDetails,
      attachments: attachments,
      notes: notes,
      timeline: timeline ?? this.timeline,
      reviewerName: reviewerName ?? this.reviewerName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class BookingCustomerProfile {
  final String name;
  final String phone;
  final String email;
  final String tripsCount;
  final String accountStatus;

  const BookingCustomerProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.tripsCount,
    required this.accountStatus,
  });
}

class BookingTripDetails {
  final String route;
  final String date;
  final String time;
  final String vehicle;
  final String driver;

  const BookingTripDetails({
    required this.route,
    required this.date,
    required this.time,
    required this.vehicle,
    required this.driver,
  });
}

class BookingPaymentDetails {
  final String amount;
  final BookingPaymentMethod method;
  final String status;
  final String reference;
  final String? receiptReference;
  final DateTime? receiptUploadedAt;
  final String? receiptUrl;

  const BookingPaymentDetails({
    required this.amount,
    required this.method,
    required this.status,
    required this.reference,
    this.receiptReference,
    this.receiptUploadedAt,
    this.receiptUrl,
  });
}

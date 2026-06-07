enum BookingStatus {
  newRequest('طلبات جديدة'),
  underReview('قيد المراجعة'),
  confirmed('مؤكدة'),
  cancelled('ملغاة');

  final String label;

  const BookingStatus(this.label);
}

enum BookingPaymentMethod {
  card('بطاقة'),
  cash('كاش'),
  wallet('محفظة'),
  bankTransfer('تحويل');

  final String label;

  const BookingPaymentMethod(this.label);
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
  final String assignedTrip;
  final BookingCustomerProfile customerProfile;
  final BookingTripDetails tripDetails;
  final BookingPaymentDetails paymentDetails;
  final List<String> attachments;
  final List<String> notes;
  final List<String> history;

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
    required this.assignedTrip,
    required this.customerProfile,
    required this.tripDetails,
    required this.paymentDetails,
    required this.attachments,
    required this.notes,
    required this.history,
  });

  OperationBooking copyWith({
    BookingStatus? status,
    String? assignedTrip,
    List<String>? history,
  }) {
    return OperationBooking(
      id: id,
      passengerName: passengerName,
      phone: phone,
      route: route,
      tripTime: tripTime,
      date: date,
      seat: seat,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      assignedTrip: assignedTrip ?? this.assignedTrip,
      customerProfile: customerProfile,
      tripDetails: tripDetails,
      paymentDetails: paymentDetails,
      attachments: attachments,
      notes: notes,
      history: history ?? this.history,
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

  const BookingPaymentDetails({
    required this.amount,
    required this.method,
    required this.status,
    required this.reference,
  });
}

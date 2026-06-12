import '../../domain/entities/operation_booking.dart';

class OperationBookingModel extends OperationBooking {
  const OperationBookingModel({
    required super.id,
    required super.passengerName,
    required super.phone,
    required super.route,
    required super.tripTime,
    required super.date,
    required super.seat,
    required super.paymentMethod,
    required super.status,
    required super.priority,
    required super.assignedTrip,
    required super.createdAt,
    required super.customerProfile,
    required super.tripDetails,
    required super.paymentDetails,
    required super.attachments,
    required super.notes,
    required super.timeline,
    super.reviewerName,
    super.rejectionReason,
  });

  factory OperationBookingModel.fromEntity(OperationBooking booking) {
    return OperationBookingModel(
      id: booking.id,
      passengerName: booking.passengerName,
      phone: booking.phone,
      route: booking.route,
      tripTime: booking.tripTime,
      date: booking.date,
      seat: booking.seat,
      paymentMethod: booking.paymentMethod,
      status: booking.status,
      priority: booking.priority,
      assignedTrip: booking.assignedTrip,
      createdAt: booking.createdAt,
      customerProfile: booking.customerProfile,
      tripDetails: booking.tripDetails,
      paymentDetails: booking.paymentDetails,
      attachments: booking.attachments,
      notes: booking.notes,
      timeline: booking.timeline,
      reviewerName: booking.reviewerName,
      rejectionReason: booking.rejectionReason,
    );
  }

  factory OperationBookingModel.fromJson(Map<String, dynamic> json) {
    final methodStr = json['payment_method'] as String? ?? 'cash';
    final paymentMethod = BookingPaymentMethod.values.firstWhere(
      (m) => m.name == methodStr,
      orElse: () => BookingPaymentMethod.cash,
    );

    final statusStr = json['status'] as String? ?? 'newRequest';
    final status = BookingStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => BookingStatus.newRequest,
    );

    final priorityStr = json['priority'] as String? ?? 'normal';
    final priority = BookingPriority.values.firstWhere(
      (p) => p.name == priorityStr,
      orElse: () => BookingPriority.normal,
    );

    final attachmentsList = (json['attachments'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final notesList = (json['notes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final timelineList = (json['timeline'] as List?)
            ?.map((e) => BookingTimelineEventModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return OperationBookingModel(
      id: json['id'] as String? ?? '',
      passengerName: json['passenger_name'] as String? ?? 'غير معروف',
      phone: json['phone'] as String? ?? '',
      route: json['route'] as String? ?? '',
      tripTime: json['trip_time'] as String? ?? '',
      date: json['trip_date'] as String? ?? '',
      seat: json['seat'] as String? ?? '',
      paymentMethod: paymentMethod,
      status: status,
      priority: priority,
      assignedTrip: json['assigned_trip'] as String? ?? 'غير مسند',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      reviewerName: json['reviewer_name'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      customerProfile: json['customer_profile'] != null
          ? BookingCustomerProfileModel.fromJson(json['customer_profile'] as Map<String, dynamic>)
          : BookingCustomerProfileModel.empty(),
      tripDetails: json['trip_details'] != null
          ? BookingTripDetailsModel.fromJson(json['trip_details'] as Map<String, dynamic>)
          : BookingTripDetailsModel.empty(),
      paymentDetails: json['payment_details'] != null
          ? BookingPaymentDetailsModel.fromJson(json['payment_details'] as Map<String, dynamic>)
          : BookingPaymentDetailsModel.empty(paymentMethod),
      attachments: attachmentsList,
      notes: notesList,
      timeline: timelineList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_name': passengerName,
      'phone': phone,
      'route': route,
      'trip_time': tripTime,
      'trip_date': date,
      'seat': seat,
      'payment_method': paymentMethod.name,
      'status': status.name,
      'priority': priority.name,
      'assigned_trip': assignedTrip,
      'created_at': createdAt.toUtc().toIso8601String(),
      'reviewer_name': reviewerName,
      'rejection_reason': rejectionReason,
      'customer_profile': (customerProfile as BookingCustomerProfileModel).toJson(),
      'trip_details': (tripDetails as BookingTripDetailsModel).toJson(),
      'payment_details': (paymentDetails as BookingPaymentDetailsModel).toJson(),
      'attachments': attachments,
      'notes': notes,
      'timeline': timeline.map((e) => (e as BookingTimelineEventModel).toJson()).toList(),
    };
  }
}

class BookingCustomerProfileModel extends BookingCustomerProfile {
  const BookingCustomerProfileModel({
    required super.name,
    required super.phone,
    required super.email,
    required super.tripsCount,
    required super.accountStatus,
  });

  factory BookingCustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return BookingCustomerProfileModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tripsCount: json['trips_count'] as String? ?? '0',
      accountStatus: json['account_status'] as String? ?? 'جديد',
    );
  }

  factory BookingCustomerProfileModel.empty() {
    return const BookingCustomerProfileModel(
      name: '',
      phone: '',
      email: '',
      tripsCount: '0',
      accountStatus: 'جديد',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'trips_count': tripsCount,
      'account_status': accountStatus,
    };
  }
}

class BookingTripDetailsModel extends BookingTripDetails {
  const BookingTripDetailsModel({
    required super.route,
    required super.date,
    required super.time,
    required super.vehicle,
    required super.driver,
  });

  factory BookingTripDetailsModel.fromJson(Map<String, dynamic> json) {
    return BookingTripDetailsModel(
      route: json['route'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      vehicle: json['vehicle'] as String? ?? '',
      driver: json['driver'] as String? ?? '',
    );
  }

  factory BookingTripDetailsModel.empty() {
    return const BookingTripDetailsModel(
      route: '',
      date: '',
      time: '',
      vehicle: '',
      driver: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route': route,
      'date': date,
      'time': time,
      'vehicle': vehicle,
      'driver': driver,
    };
  }
}

class BookingPaymentDetailsModel extends BookingPaymentDetails {
  const BookingPaymentDetailsModel({
    required super.amount,
    required super.method,
    required super.status,
    required super.reference,
    super.receiptReference,
    super.receiptUploadedAt,
  });

  factory BookingPaymentDetailsModel.fromJson(Map<String, dynamic> json) {
    final methodStr = json['method'] as String? ?? 'cash';
    final paymentMethod = BookingPaymentMethod.values.firstWhere(
      (m) => m.name == methodStr,
      orElse: () => BookingPaymentMethod.cash,
    );

    return BookingPaymentDetailsModel(
      amount: json['amount'] as String? ?? '0 ج.م',
      method: paymentMethod,
      status: json['status'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      receiptReference: json['receipt_reference'] as String?,
      receiptUploadedAt: json['receipt_uploaded_at'] != null
          ? DateTime.parse(json['receipt_uploaded_at'] as String).toLocal()
          : null,
    );
  }

  factory BookingPaymentDetailsModel.empty(BookingPaymentMethod method) {
    return BookingPaymentDetailsModel(
      amount: '0 ج.م',
      method: method,
      status: 'غير مدفوع',
      reference: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method.name,
      'status': status,
      'reference': reference,
      'receipt_reference': receiptReference,
      'receipt_uploaded_at': receiptUploadedAt?.toUtc().toIso8601String(),
    };
  }
}

class BookingTimelineEventModel extends BookingTimelineEvent {
  const BookingTimelineEventModel({
    required super.timestamp,
    required super.action,
    required super.actor,
    super.note,
  });

  factory BookingTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return BookingTimelineEventModel(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String).toLocal()
          : DateTime.now(),
      action: json['action'] as String? ?? '',
      actor: json['actor'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  factory BookingTimelineEventModel.fromEntity(BookingTimelineEvent event) {
    return BookingTimelineEventModel(
      timestamp: event.timestamp,
      action: event.action,
      actor: event.actor,
      note: event.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'action': action,
      'actor': actor,
      'note': note,
    };
  }
}

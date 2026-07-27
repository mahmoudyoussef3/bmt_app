import '../../domain/entities/operation_booking.dart';

class OperationBookingModel extends OperationBooking {
  const OperationBookingModel({
    required super.id,
    required super.bookingNumber,
    required super.clientId,
    required super.passengerName,
    required super.phone,
    required super.route,
    required super.tripTime,
    required super.date,
    required super.seat,
    required super.paymentMethod,
    required super.status,
    required super.paymentStatus,
    required super.paymentAmount,
    required super.packageName,
    required super.createdAt,
    required super.tripDetails,
    required super.notes,
    required super.timeline,
    super.receiptUrl,
    super.rejectionReason,
    super.reviewedAt,
  });

  /// Columns selected by [SupabaseBookingsDatasource]. Kept in one place so the
  /// list query and single-row refetch never drift apart.
  static const columns = '''
    id, booking_number, client_id, passenger_name, phone, route, trip_time,
    trip_date, seat, payment_method, status, payment_status, payment_amount,
    payment_receipt_url, payment_rejection_reason, reviewed_at, created_at,
    notes,
    package:transport_packages(name_ar, name_en),
    trip:operation_trips(
      id, trip_date, departure_time,
      route:operation_routes(name),
      driver:drivers(full_name),
      vehicle:vehicles(plate_number)
    )
  ''';

  factory OperationBookingModel.fromJson(Map<String, dynamic> json) {
    final tripJson = json['trip'] as Map<String, dynamic>?;
    final routeJson = tripJson?['route'] as Map<String, dynamic>?;
    final driverJson = tripJson?['driver'] as Map<String, dynamic>?;
    final vehicleJson = tripJson?['vehicle'] as Map<String, dynamic>?;
    final packageJson = json['package'] as Map<String, dynamic>?;

    final createdAt = _parseDate(json['created_at']) ?? DateTime.now();
    final reviewedAt = _parseDate(json['reviewed_at']);
    final route = json['route'] as String? ?? '';
    final tripTime = json['trip_time'] as String? ?? '';
    final tripDate = json['trip_date'] as String? ?? '';
    final status = _enumByName(
      BookingStatus.values,
      json['status'] as String?,
      BookingStatus.draft,
    );
    final paymentStatus = _enumByName(
      PaymentStatus.values,
      json['payment_status'] as String?,
      PaymentStatus.pending,
    );
    final rejection = (json['payment_rejection_reason'] as String?)?.trim();

    return OperationBookingModel(
      id: json['id'] as String? ?? '',
      bookingNumber: json['booking_number'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      passengerName: json['passenger_name'] as String? ?? 'غير معروف',
      phone: json['phone'] as String? ?? '',
      route: route,
      tripTime: tripTime,
      date: tripDate,
      seat: json['seat'] as String? ?? '',
      paymentMethod: _method(json['payment_method'] as String?),
      status: status,
      paymentStatus: paymentStatus,
      paymentAmount: _toDouble(json['payment_amount']),
      packageName:
          packageJson?['name_ar'] as String? ??
          packageJson?['name_en'] as String? ??
          '',
      receiptUrl: json['payment_receipt_url'] as String?,
      rejectionReason: (rejection?.isEmpty ?? true) ? null : rejection,
      reviewedAt: reviewedAt,
      createdAt: createdAt,
      tripDetails: BookingTripDetails(
        tripId: tripJson?['id'] as String? ?? '',
        route: routeJson?['name'] as String? ?? route,
        date: tripJson?['trip_date'] as String? ?? tripDate,
        time: tripJson?['departure_time'] as String? ?? tripTime,
        vehicle: vehicleJson?['plate_number'] as String? ?? '',
        driver: driverJson?['full_name'] as String? ?? '',
      ),
      notes: (json['notes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      timeline: _timeline(
        createdAt: createdAt,
        reviewedAt: reviewedAt,
        status: status,
        paymentStatus: paymentStatus,
        rejection: rejection,
      ),
    );
  }

  /// Builds the lifecycle history from real row timestamps rather than a
  /// separately-maintained (and easily stale) audit blob.
  static List<BookingTimelineEvent> _timeline({
    required DateTime createdAt,
    required DateTime? reviewedAt,
    required BookingStatus status,
    required PaymentStatus paymentStatus,
    required String? rejection,
  }) {
    final events = <BookingTimelineEvent>[
      BookingTimelineEvent(timestamp: createdAt, action: 'تم إنشاء الحجز'),
    ];
    if (reviewedAt != null) {
      final approved = paymentStatus == PaymentStatus.approved;
      events.add(
        BookingTimelineEvent(
          timestamp: reviewedAt,
          action: approved ? 'تم اعتماد الدفع' : 'تم رفض الدفع',
          note: approved ? null : rejection,
        ),
      );
    }
    return events;
  }

  static BookingPaymentMethod _method(String? raw) => switch (raw) {
    'bank_transfer' || 'bankTransfer' => BookingPaymentMethod.bankTransfer,
    'vodafone_cash' || 'vodafoneCash' => BookingPaymentMethod.vodafoneCash,
    'instapay' || 'instaPay' => BookingPaymentMethod.instaPay,
    'credit_card' || 'card' => BookingPaymentMethod.card,
    _ => BookingPaymentMethod.cash,
  };

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    return values.firstWhere((v) => v.name == name, orElse: () => fallback);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

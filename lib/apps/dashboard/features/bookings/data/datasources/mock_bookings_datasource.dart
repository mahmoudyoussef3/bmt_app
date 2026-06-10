import 'dart:math';

import '../../domain/entities/operation_booking.dart';
import '../models/operation_booking_model.dart';

abstract class BookingsDatasource {
  Future<List<OperationBookingModel>> fetchBookings();
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  );
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  );
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  );
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  );
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  );
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  );
}

class MockBookingsDatasource implements BookingsDatasource {
  late final List<OperationBookingModel> _bookings;

  MockBookingsDatasource() {
    _bookings = List<OperationBookingModel>.from(_generateMockBookings());
  }

  @override
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  ) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw ArgumentError('الحجز غير موجود');
    final booking = _bookings[index];
    final event = BookingTimelineEvent(
      timestamp: DateTime.now(),
      action: 'تم قبول الدفع',
      actor: reviewer,
      note: note,
    );
    final updated = OperationBookingModel.fromEntity(
      booking.copyWith(
        status: BookingStatus.approved,
        reviewerName: reviewer,
        timeline: [event, ...booking.timeline],
      ),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  ) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw ArgumentError('الحجز غير موجود');
    final booking = _bookings[index];
    final event = BookingTimelineEvent(
      timestamp: DateTime.now(),
      action: 'تم رفض الدفع',
      actor: reviewer,
      note: '$reason${note != null ? ' - $note' : ''}',
    );
    final updated = OperationBookingModel.fromEntity(
      booking.copyWith(
        status: BookingStatus.rejected,
        reviewerName: reviewer,
        rejectionReason: reason,
        timeline: [event, ...booking.timeline],
      ),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  ) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw ArgumentError('الحجز غير موجود');
    final booking = _bookings[index];
    final event = BookingTimelineEvent(
      timestamp: DateTime.now(),
      action: 'طلب إعادة رفع الإيصال',
      actor: reviewer,
      note: reason,
    );
    final updated = OperationBookingModel.fromEntity(
      booking.copyWith(
        status: BookingStatus.requestReupload,
        reviewerName: reviewer,
        timeline: [event, ...booking.timeline],
      ),
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index == -1) continue;
      final booking = _bookings[index];
      final event = BookingTimelineEvent(
        timestamp: DateTime.now(),
        action: 'تم الإسناد إلى رحلة $tripId',
        actor: 'النظام',
      );
      final model = OperationBookingModel.fromEntity(
        booking.copyWith(
          assignedTrip: tripId,
          timeline: [event, ...booking.timeline],
        ),
      );
      _bookings[index] = model;
      updated.add(model);
    }
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      updated.add(await updateBookingStatus(id, status));
    }
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> fetchBookings() async {
    return List<OperationBookingModel>.unmodifiable(_bookings);
  }

  @override
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw ArgumentError('الحجز غير موجود');
    final booking = _bookings[index];
    final event = BookingTimelineEvent(
      timestamp: DateTime.now(),
      action: 'تم تحديث الحالة إلى ${status.label}',
      actor: 'النظام',
    );
    final model = OperationBookingModel.fromEntity(
      booking.copyWith(
        status: status,
        timeline: [event, ...booking.timeline],
      ),
    );
    _bookings[index] = model;
    return model;
  }
}

// ---------------------------------------------------------------------------
// Mock Data Generation
// ---------------------------------------------------------------------------

const _names = [
  'سارة أحمد',
  'خالد محمود',
  'رنا يوسف',
  'ياسمين علي',
  'محمود حسن',
  'نورهان عادل',
  'إسلام فتحي',
  'فاطمة محمد',
  'أحمد سمير',
  'هبة الله',
  'عمرو طارق',
  'مريم خالد',
  'محمد عبدالله',
  'دينا سعيد',
  'يوسف إبراهيم',
  'شيماء وائل',
  'كريم مصطفى',
  'سلمى أشرف',
  'عبدالرحمن حسام',
  'لمياء جمال',
  'حسن شريف',
  'ندى رضا',
  'طارق وليد',
  'رحاب ممدوح',
  'أمير عصام',
  'جيهان نبيل',
  'بلال سامح',
  'ريم حاتم',
  'مصطفى كمال',
  'هالة عبدالعزيز',
  'عادل راضي',
  'مها السيد',
  'حازم فؤاد',
  'سحر إيهاب',
  'وليد جابر',
  'آلاء منير',
  'تامر بهاء',
  'علا مجدي',
  'أسامة هشام',
  'ياسر رمزي',
];

const _phones = [
  '٠١٠١٢٣٤٥٦٧٨',
  '٠١٢٣٤٥٦٧٨٩٠',
  '٠١١١٢٢٢٣٣٣٤',
  '٠١٥٥٦٦٦٧٧٧٨',
  '٠١٠٩٩٨٨٧٧٦٦',
  '٠١٢٧٧٨٨٩٩٠٠',
  '٠١٠٠١٢٣٤٥٦٧',
  '٠١١١٨٨٧٧٦٦٥',
  '٠١٥٥١٢٣٤٥٦٧',
  '٠١٢٢٣٣٤٤٥٥٦',
  '٠١٠٠٥٦٧٨٩٠١',
  '٠١١١٩٨٧٦٥٤٣',
  '٠١٢٨٧٦٥٤٣٢١',
  '٠١٥٥٤٣٢١٠٩٨',
  '٠١٠٩٨٧٦٥٤٣٢',
  '٠١٢٣٢١٠٩٨٧٦',
  '٠١٠٢٣٤٥٦٧٨٩',
  '٠١١١٣٤٥٦٧٨٩',
  '٠١٥٥٧٨٩٠١٢٣',
  '٠١٢٧٨٩٠١٢٣٤',
];

const _routes = [
  'بنها - القرية الذكية',
  'بنها - مدينة نصر',
  'بنها - المهندسين',
  'بنها - التجمع الخامس',
  'بنها - الشيخ زايد',
  'بنها - ٦ أكتوبر',
  'بنها - المعادي',
  'بنها - وسط البلد',
  'بنها - العباسية',
  'بنها - حلوان',
];

const _times = [
  '٦:٠٠ صباحاً',
  '٦:٣٠ صباحاً',
  '٧:٠٠ صباحاً',
  '٧:٣٠ صباحاً',
  '٨:٠٠ صباحاً',
  '٨:٣٠ صباحاً',
  '٩:٠٠ صباحاً',
  '١٠:٠٠ صباحاً',
  '١٢:٠٠ ظهراً',
  '٢:٠٠ ظهراً',
  '٤:٠٠ عصراً',
  '٦:٠٠ مساءً',
];

const _vehicles = [
  'أ ب ج ٤٥٦',
  'م ن و ٧٨٩',
  'ت ث ج ١٢٣',
  'ع غ ف ٣٤٥',
  'س ش ص ٦٧٨',
  'ل م ن ٩٠١',
  'ق ر س ٢٣٤',
  'هـ و ي ٥٦٧',
];

const _drivers = [
  'محمد أحمد',
  'حسن علي',
  'عبدالله إبراهيم',
  'إبراهيم سعد',
  'سعيد محمود',
  'ممدوح فتحي',
  'رمضان حسين',
  'فتحي عبدالرحمن',
];

const _tripIds = [
  'TR-219',
  'TR-220',
  'TR-221',
  'TR-222',
  'TR-223',
  'TR-224',
  'TR-225',
  'TR-226',
  'TR-227',
  'TR-228',
];

const _rejectionReasons = [
  'الإيصال غير واضح',
  'المبلغ غير مطابق',
  'إيصال منتهي الصلاحية',
  'رقم المرجع غير صحيح',
  'صورة مقطوعة أو ناقصة',
];

const _reviewers = [
  'مروة حسين',
  'أحمد نصر',
  'سمر مصطفى',
];

List<OperationBookingModel> _generateMockBookings() {
  final random = Random(42);
  final now = DateTime.now();
  final bookings = <OperationBookingModel>[];

  // Status distribution: realistic for an operations center
  // ~15 newRequest, ~20 paymentUploaded, ~25 underReview, ~12 approved,
  // ~8 rejected, ~5 requestReupload, ~10 confirmed, ~5 cancelled
  final statusDistribution = [
    ...List.filled(15, BookingStatus.newRequest),
    ...List.filled(20, BookingStatus.paymentUploaded),
    ...List.filled(25, BookingStatus.underReview),
    ...List.filled(12, BookingStatus.approved),
    ...List.filled(8, BookingStatus.rejected),
    ...List.filled(5, BookingStatus.requestReupload),
    ...List.filled(10, BookingStatus.confirmed),
    ...List.filled(5, BookingStatus.cancelled),
  ];

  for (var i = 0; i < statusDistribution.length; i++) {
    final id = 'B-${1001 + i}';
    final nameIdx = i % _names.length;
    final phoneIdx = i % _phones.length;
    final routeIdx = random.nextInt(_routes.length);
    final timeIdx = random.nextInt(_times.length);
    final vehicleIdx = random.nextInt(_vehicles.length);
    final driverIdx = random.nextInt(_drivers.length);
    final tripIdx = random.nextInt(_tripIds.length);
    final status = statusDistribution[i];
    final seat = '${random.nextInt(14) + 1}';
    final createdAt = now.subtract(Duration(
      hours: random.nextInt(72),
      minutes: random.nextInt(60),
    ));

    final method = BookingPaymentMethod
        .values[random.nextInt(BookingPaymentMethod.values.length)];

    final priority = i % 7 == 0
        ? BookingPriority.vip
        : (i % 5 == 0 ? BookingPriority.urgent : BookingPriority.normal);

    final hasReceipt = status != BookingStatus.newRequest;
    final receiptRef = hasReceipt ? 'RCP-${random.nextInt(999999)}' : null;
    final receiptTime = hasReceipt
        ? createdAt.add(Duration(minutes: random.nextInt(120) + 10))
        : null;

    final isRejected = status == BookingStatus.rejected;
    final rejectionReason =
        isRejected ? _rejectionReasons[random.nextInt(_rejectionReasons.length)] : null;

    final isReviewed = status == BookingStatus.approved ||
        status == BookingStatus.rejected ||
        status == BookingStatus.requestReupload ||
        status == BookingStatus.confirmed;
    final reviewer =
        isReviewed ? _reviewers[random.nextInt(_reviewers.length)] : null;

    final isAssigned = status == BookingStatus.confirmed ||
        status == BookingStatus.approved ||
        (status == BookingStatus.underReview && random.nextBool());
    final assignedTrip = isAssigned ? _tripIds[tripIdx] : 'غير مسند';

    final dates = [
      'اليوم',
      'غداً',
      'بعد غد',
      '٢٠٢٦/٠٦/١٠',
      '٢٠٢٦/٠٦/١١',
      '٢٠٢٦/٠٦/١٢',
    ];

    final timeline = _buildTimeline(status, createdAt, reviewer, rejectionReason, random);

    final tripsCount = '${random.nextInt(50) + 1} رحلة';
    final accountStatuses = ['نشط', 'نشط', 'نشط', 'معلق', 'جديد'];

    bookings.add(
      OperationBookingModel(
        id: id,
        passengerName: _names[nameIdx],
        phone: _phones[phoneIdx],
        route: _routes[routeIdx],
        tripTime: _times[timeIdx],
        date: dates[random.nextInt(dates.length)],
        seat: seat,
        paymentMethod: method,
        status: status,
        priority: priority,
        assignedTrip: assignedTrip,
        createdAt: createdAt,
        reviewerName: reviewer,
        rejectionReason: rejectionReason,
        customerProfile: BookingCustomerProfile(
          name: _names[nameIdx],
          phone: _phones[phoneIdx],
          email: '${id.toLowerCase()}@bmt.local',
          tripsCount: tripsCount,
          accountStatus: accountStatuses[random.nextInt(accountStatuses.length)],
        ),
        tripDetails: BookingTripDetails(
          route: _routes[routeIdx],
          date: dates[random.nextInt(dates.length)],
          time: _times[timeIdx],
          vehicle: _vehicles[vehicleIdx],
          driver: _drivers[driverIdx],
        ),
        paymentDetails: BookingPaymentDetails(
          amount: '${(random.nextInt(15) + 5) * 10} ج.م',
          method: method,
          status: _paymentStatusForBookingStatus(status),
          reference: 'PAY-$id',
          receiptReference: receiptRef,
          receiptUploadedAt: receiptTime,
        ),
        attachments: hasReceipt
            ? ['إيصال_دفع_$id.jpg', 'تأكيد_حجز_$id.pdf']
            : [],
        notes: _buildNotes(status, random),
        timeline: timeline,
      ),
    );
  }

  // Shuffle so statuses are mixed in the list
  bookings.shuffle(random);
  return bookings;
}

String _paymentStatusForBookingStatus(BookingStatus status) {
  return switch (status) {
    BookingStatus.newRequest => 'في انتظار الدفع',
    BookingStatus.paymentUploaded => 'تم الرفع - في انتظار المراجعة',
    BookingStatus.underReview => 'قيد المراجعة',
    BookingStatus.approved => 'مقبول',
    BookingStatus.rejected => 'مرفوض',
    BookingStatus.requestReupload => 'مطلوب إعادة رفع',
    BookingStatus.confirmed => 'مؤكد',
    BookingStatus.cancelled => 'ملغى',
  };
}

List<BookingTimelineEvent> _buildTimeline(
  BookingStatus status,
  DateTime createdAt,
  String? reviewer,
  String? reason,
  Random random,
) {
  final events = <BookingTimelineEvent>[
    BookingTimelineEvent(
      timestamp: createdAt,
      action: 'تم إنشاء طلب الحجز',
      actor: 'العميل',
    ),
  ];

  if (status == BookingStatus.newRequest) return events.reversed.toList();

  events.add(BookingTimelineEvent(
    timestamp: createdAt.add(Duration(minutes: random.nextInt(60) + 5)),
    action: 'تم رفع إيصال الدفع',
    actor: 'العميل',
  ));

  if (status == BookingStatus.paymentUploaded) return events.reversed.toList();

  events.add(BookingTimelineEvent(
    timestamp: createdAt.add(Duration(minutes: random.nextInt(120) + 30)),
    action: 'بدأت مراجعة الإيصال',
    actor: reviewer ?? 'خدمة العملاء',
  ));

  if (status == BookingStatus.underReview) return events.reversed.toList();

  if (status == BookingStatus.approved || status == BookingStatus.confirmed) {
    events.add(BookingTimelineEvent(
      timestamp: createdAt.add(Duration(minutes: random.nextInt(180) + 60)),
      action: 'تم قبول الدفع',
      actor: reviewer ?? 'خدمة العملاء',
    ));
  }

  if (status == BookingStatus.confirmed) {
    events.add(BookingTimelineEvent(
      timestamp: createdAt.add(Duration(minutes: random.nextInt(240) + 120)),
      action: 'تم تأكيد المقعد',
      actor: reviewer ?? 'النظام',
    ));
  }

  if (status == BookingStatus.rejected) {
    events.add(BookingTimelineEvent(
      timestamp: createdAt.add(Duration(minutes: random.nextInt(180) + 60)),
      action: 'تم رفض الدفع',
      actor: reviewer ?? 'خدمة العملاء',
      note: reason,
    ));
  }

  if (status == BookingStatus.requestReupload) {
    events.add(BookingTimelineEvent(
      timestamp: createdAt.add(Duration(minutes: random.nextInt(180) + 60)),
      action: 'تم طلب إعادة رفع الإيصال',
      actor: reviewer ?? 'خدمة العملاء',
      note: reason,
    ));
  }

  if (status == BookingStatus.cancelled) {
    events.add(BookingTimelineEvent(
      timestamp: createdAt.add(Duration(minutes: random.nextInt(300) + 30)),
      action: 'تم إلغاء الحجز',
      actor: 'العميل',
    ));
  }

  return events.reversed.toList();
}

List<String> _buildNotes(BookingStatus status, Random random) {
  final notes = <String>[];
  if (random.nextBool()) notes.add('العميل يطلب تأكيد سريع');
  if (status == BookingStatus.rejected) {
    notes.add('يرجى التواصل مع العميل لإعادة الرفع');
  }
  if (random.nextInt(7) == 0) {
    notes.add('عميل VIP - أولوية في المعالجة');
  }
  return notes;
}

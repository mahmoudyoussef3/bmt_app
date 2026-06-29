import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import '../../domain/entities/dashboard_home_data.dart';
import '../models/dashboard_home_model.dart';
import 'dashboard_home_datasource.dart';

class SupabaseDashboardHomeDatasource implements DashboardHomeDatasource {
  const SupabaseDashboardHomeDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<DashboardHomeModel> fetchHomeData() async {
    try {
      final now = DateTime.now();
      final today = _dateOnly(now);
      final soon = _dateOnly(now.add(const Duration(days: 14)));

      final results = await Future.wait([
        _fetchTodayTrips(today, now),
        _fetchPaymentReviews(),
        _fetchOpenComplaints(),
        _fetchSubscriptions(today),
        _fetchExpiredDocuments(soon),
        _fetchPendingStarts(today, now),
      ]);

      final todayTrips = results[0] as List<TodayTripSummary>;
      final paymentReviews = results[1] as List<PaymentReviewItem>;
      final complaints = results[2] as List<ComplaintTicket>;
      final subscriptions = results[3] as List<SubscriptionReviewItem>;
      final documentAlerts = results[4] as _DocumentAlertCounts;
      final pendingStarts = results[5] as _TripStartCounts;

      final actionItems = <OperationsActionItem>[
        if (paymentReviews.isNotEmpty)
          OperationsActionItem(
            title: 'حجوزات بانتظار مراجعة الدفع',
            count: _arabicNumber(paymentReviews.length),
            description: 'إيصالات أو مدفوعات تحتاج اعتماد قبل تثبيت المقاعد',
            targetModule: DashboardRoutes.paymentVerification,
            priority: OperationsPriority.urgent,
          ),
        if (complaints.isNotEmpty)
          OperationsActionItem(
            title: 'شكاوى مفتوحة',
            count: _arabicNumber(complaints.length),
            description: 'بلاغات عملاء تحتاج متابعة من خدمة العملاء',
            targetModule: DashboardRoutes.tickets,
            priority: OperationsPriority.high,
          ),
        if (subscriptions.isNotEmpty)
          OperationsActionItem(
            title: 'اشتراكات تحتاج متابعة',
            count: _arabicNumber(subscriptions.length),
            description: 'اشتراكات متوقفة أو قاربت على الانتهاء',
            targetModule: DashboardRoutes.subscriptions,
            priority: OperationsPriority.high,
          ),
        if (pendingStarts.lateTrips > 0)
          OperationsActionItem(
            title: 'رحلات متأخرة عن البدء',
            count: _arabicNumber(pendingStarts.lateTrips),
            description:
                'رحلات اليوم تجاوزت وقت الانطلاق ولم تبدأ من تطبيق السائق',
            targetModule: DashboardRoutes.liveTrips,
            priority: OperationsPriority.urgent,
          ),
        if (pendingStarts.dueSoonTrips > 0)
          OperationsActionItem(
            title: 'رحلات قريبة لم تبدأ',
            count: _arabicNumber(pendingStarts.dueSoonTrips),
            description:
                'رحلات خلال الساعة القادمة تحتاج تأكيد جاهزية السائق والمركبة',
            targetModule: DashboardRoutes.trips,
            priority: OperationsPriority.high,
          ),
        if (documentAlerts.expiredVehicles > 0)
          OperationsActionItem(
            title: 'مستندات مركبات منتهية',
            count: _arabicNumber(documentAlerts.expiredVehicles),
            description: 'مركبات لا يجب تشغيلها قبل تجديد المستندات',
            targetModule: DashboardRoutes.vehicles,
            priority: OperationsPriority.urgent,
          ),
        if (documentAlerts.expiringDrivers > 0)
          OperationsActionItem(
            title: 'رخص سائقين قاربت على الانتهاء',
            count: _arabicNumber(documentAlerts.expiringDrivers),
            description: 'رخص تنتهي خلال ١٤ يوم وتحتاج متابعة قبل التشغيل',
            targetModule: DashboardRoutes.drivers,
            priority: OperationsPriority.normal,
          ),
      ];

      final alerts = <OperationsAlert>[
        if (pendingStarts.lateTrips > 0)
          OperationsAlert(
            title: 'رحلات اليوم متأخرة عن الانطلاق',
            details:
                '${_arabicNumber(pendingStarts.lateTrips)} رحلة لم تتحول إلى جارية بعد وقت الانطلاق',
            targetModule: DashboardRoutes.liveTrips,
            priority: OperationsPriority.urgent,
          ),
        if (documentAlerts.expiredVehicles > 0)
          OperationsAlert(
            title: 'مستند مركبة منتهي',
            details:
                '${_arabicNumber(documentAlerts.expiredVehicles)} مركبة لديها مستند منتهي',
            targetModule: DashboardRoutes.vehicles,
            priority: OperationsPriority.urgent,
          ),
        if (documentAlerts.expiringDrivers > 0)
          OperationsAlert(
            title: 'رخصة سائق تحتاج تجديد قريب',
            details:
                '${_arabicNumber(documentAlerts.expiringDrivers)} رخصة تنتهي خلال ١٤ يوم',
            targetModule: DashboardRoutes.drivers,
            priority: OperationsPriority.high,
          ),
        ...todayTrips
            .where((trip) => trip.availableSeats == 0 && trip.capacity > 0)
            .take(3)
            .map(
              (trip) => OperationsAlert(
                title: 'رحلة ممتلئة بالكامل',
                details: '${trip.name} لا يوجد بها مقاعد متاحة',
                targetModule: DashboardRoutes.trips,
                priority: OperationsPriority.normal,
              ),
            ),
      ];

      return DashboardHomeModel(
        actionItems: actionItems,
        todayTrips: todayTrips,
        paymentReviews: paymentReviews,
        openComplaints: complaints,
        subscriptions: subscriptions,
        alerts: alerts,
      );
    } on PostgrestException catch (error) {
      throw Exception('تعذر تحميل بيانات مركز التشغيل: ${error.message}');
    } catch (error) {
      throw Exception('تعذر تحميل بيانات مركز التشغيل: $error');
    }
  }

  Future<List<TodayTripSummary>> _fetchTodayTrips(
    String today,
    DateTime now,
  ) async {
    final response = await _client
        .from('operation_trips')
        .select('''
          id,
          trip_code,
          trip_date,
          departure_time,
          status,
          capacity,
          booked_seats,
          passenger_count,
          route:operation_routes(name),
          driver:drivers(full_name),
          vehicle:vehicles(vehicle_code, plate_number, vehicle_type)
        ''')
        .eq('trip_date', today)
        .order('departure_time')
        .limit(8);

    return response
        .map<TodayTripSummary>((json) => _todayTripFromJson(json, now))
        .toList();
  }

  Future<List<PaymentReviewItem>> _fetchPaymentReviews() async {
    final response = await _client
        .from('operation_bookings')
        .select('''
          passenger_name,
          route,
          trip_time,
          trip_date,
          payment_method,
          payment_details,
          payment_amount,
          attachments,
          status,
          created_at
        ''')
        .or('status.eq.paymentUploaded,status.eq.underReview')
        .order('created_at', ascending: false)
        .limit(6);

    return response.map<PaymentReviewItem>(_paymentReviewFromJson).toList();
  }

  Future<List<ComplaintTicket>> _fetchOpenComplaints() async {
    final response = await _client
        .from('support_tickets')
        .select('''
          title,
          category,
          status,
          priority,
          assigned_agent_name,
          related_trip_id,
          created_at,
          updated_at,
          clients:client_id(full_name)
        ''')
        .order('updated_at', ascending: false)
        .limit(20);

    return response
        .where((json) => !_closedTicketStatuses.contains(json['status']))
        .take(6)
        .map<ComplaintTicket>(_complaintFromJson)
        .toList();
  }

  Future<List<SubscriptionReviewItem>> _fetchSubscriptions(String today) async {
    final response = await _client
        .from('subscriptions')
        .select('''
          customer_name,
          package_name,
          route_name,
          start_date,
          end_date,
          status,
          remaining_amount,
          clients:client_id(full_name)
        ''')
        .order('updated_at', ascending: false)
        .limit(20);

    return response
        .where((json) => _subscriptionNeedsFollowUp(json, today))
        .take(6)
        .map<SubscriptionReviewItem>(_subscriptionFromJson)
        .toList();
  }

  Future<_DocumentAlertCounts> _fetchExpiredDocuments(String soon) async {
    final vehicleDocuments = await _client
        .from('vehicle_documents')
        .select('vehicle_id, status, expiry_date')
        .lte('expiry_date', soon);
    final driverDocuments = await _client
        .from('driver_documents')
        .select('driver_id, status, expiry_date')
        .lte('expiry_date', soon);

    return _DocumentAlertCounts(
      expiredVehicles: vehicleDocuments
          .where(_documentExpired)
          .map((json) => json['vehicle_id'])
          .toSet()
          .length,
      expiringDrivers: driverDocuments
          .where((json) => !_documentExpired(json))
          .map((json) => json['driver_id'])
          .toSet()
          .length,
    );
  }

  Future<_TripStartCounts> _fetchPendingStarts(
    String today,
    DateTime now,
  ) async {
    final response = await _client
        .from('operation_trips')
        .select('departure_time, status')
        .eq('trip_date', today)
        .or(
          'status.eq.open_for_booking,status.eq.boarding,status.eq.in_progress',
        );

    var late = 0;
    var dueSoon = 0;
    for (final json in response) {
      final departure = _combineDateAndTime(today, json['departure_time']);
      if (departure == null) continue;
      final diff = departure.difference(now);
      if (diff.isNegative) {
        late++;
      } else if (diff.inMinutes <= 60) {
        dueSoon++;
      }
    }

    return _TripStartCounts(lateTrips: late, dueSoonTrips: dueSoon);
  }

  TodayTripSummary _todayTripFromJson(Map<String, dynamic> json, DateTime now) {
    final route = json['route'] as Map<String, dynamic>?;
    final driver = json['driver'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final departure = _timeText(json['departure_time']);
    final status = json['status']?.toString() ?? 'scheduled';
    final departureDateTime = _combineDateAndTime(
      json['trip_date']?.toString() ?? _dateOnly(now),
      json['departure_time'],
    );
    final isLate =
        status == 'open_for_booking' &&
        departureDateTime != null &&
        departureDateTime.isBefore(now);

    final capacity = _intValue(json['capacity']);
    final booked = _intValue(json['booked_seats']);
    final passengers = _intValue(json['passenger_count']);

    return TodayTripSummary(
      name: json['trip_code']?.toString() ?? 'رحلة بدون رقم',
      route: route?['name']?.toString() ?? 'مسار غير محدد',
      driver: driver?['full_name']?.toString() ?? 'بدون سائق',
      vehicle: _vehicleLabel(vehicle),
      departureTime: departure,
      capacity: capacity,
      bookedSeats: booked > 0 ? booked : passengers,
      status: isLate ? 'متأخرة' : _tripStatusLabel(status),
    );
  }

  PaymentReviewItem _paymentReviewFromJson(Map<String, dynamic> json) {
    final details = json['payment_details'] as Map<String, dynamic>? ?? {};
    final attachments = json['attachments'] as List? ?? const [];
    final receiptUploadedAt = DateTime.tryParse(
      details['receipt_uploaded_at']?.toString() ??
          json['created_at']?.toString() ??
          '',
    );
    final reference =
        details['receipt_reference']?.toString() ??
        details['reference']?.toString() ??
        '';
    final amount = _moneyText(
      details['amount']?.toString() ?? json['payment_amount']?.toString(),
    );

    return PaymentReviewItem(
      customerName: json['passenger_name']?.toString() ?? 'عميل غير محدد',
      tripName:
          '${json['route']?.toString() ?? 'مسار غير محدد'} - ${_timeText(json['trip_time'])}',
      method: _paymentMethodLabel(json['payment_method']?.toString()),
      amount: amount,
      receiptTitle: attachments.isEmpty
          ? 'بيانات الدفع المرفوعة'
          : 'إيصال دفع مرفوع',
      receiptMeta: [
        if (reference.isNotEmpty) 'مرجع: $reference',
        if (receiptUploadedAt != null) _relativeTime(receiptUploadedAt),
      ].join(' - '),
    );
  }

  ComplaintTicket _complaintFromJson(Map<String, dynamic> json) {
    final client = json['clients'] as Map<String, dynamic>?;
    final updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '');

    return ComplaintTicket(
      customerName: client?['full_name']?.toString() ?? 'عميل غير محدد',
      type: json['category']?.toString() ?? 'شكوى',
      tripName: json['title']?.toString() ?? 'بدون عنوان',
      lastUpdate: updatedAt == null ? '' : _relativeTime(updatedAt),
      owner: json['assigned_agent_name']?.toString().isNotEmpty == true
          ? json['assigned_agent_name'].toString()
          : 'غير مسند',
      status: _ticketStatusLabel(json['status']?.toString()),
    );
  }

  SubscriptionReviewItem _subscriptionFromJson(Map<String, dynamic> json) {
    final client = json['clients'] as Map<String, dynamic>?;
    final endDate = DateTime.tryParse(json['end_date']?.toString() ?? '');
    final remainingDays = endDate == null
        ? 0
        : endDate.difference(DateTime.now()).inDays.clamp(0, 999);

    return SubscriptionReviewItem(
      customerName: json['customer_name']?.toString().isNotEmpty == true
          ? json['customer_name'].toString()
          : client?['full_name']?.toString() ?? 'عميل غير محدد',
      packageName: json['package_name']?.toString() ?? 'اشتراك',
      route: json['route_name']?.toString() ?? 'مسار غير محدد',
      startDate: _dateText(json['start_date']),
      endDate: _dateText(json['end_date']),
      remainingTrips: remainingDays,
      status: _subscriptionStatusLabel(json['status']?.toString(), endDate),
    );
  }

  bool _subscriptionNeedsFollowUp(Map<String, dynamic> json, String today) {
    final status = json['status']?.toString();
    if (status == 'paused' || status == 'expired') return true;

    final remainingAmount =
        num.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0;
    if (remainingAmount > 0) return true;

    final endDate = DateTime.tryParse(json['end_date']?.toString() ?? '');
    if (endDate == null) return false;
    return endDate.difference(DateTime.now()).inDays <= 7;
  }
}

const _closedTicketStatuses = {'closed', 'resolved', 'rejected'};

class _DocumentAlertCounts {
  const _DocumentAlertCounts({
    required this.expiredVehicles,
    required this.expiringDrivers,
  });

  final int expiredVehicles;
  final int expiringDrivers;
}

class _TripStartCounts {
  const _TripStartCounts({required this.lateTrips, required this.dueSoonTrips});

  final int lateTrips;
  final int dueSoonTrips;
}

String _dateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _arabicNumber(Object value) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value.toString().replaceAllMapped(
    RegExp(r'\d'),
    (match) => digits[int.parse(match.group(0)!)],
  );
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _vehicleLabel(Map<String, dynamic>? vehicle) {
  if (vehicle == null) return 'بدون مركبة';
  final type = vehicle['vehicle_type']?.toString() ?? '';
  final code = vehicle['vehicle_code']?.toString() ?? '';
  final plate = vehicle['plate_number']?.toString() ?? '';
  return [type, code, plate].where((part) => part.isNotEmpty).join(' ');
}

String _tripStatusLabel(String status) {
  return switch (status) {
    'boarding' => 'صعود الركاب',
    'in_progress' => 'في الطريق',
    'completed' => 'مكتملة',
    'cancelled' => 'ملغاة',
    _ => 'لم تبدأ',
  };
}

String _ticketStatusLabel(String? status) {
  return switch (status) {
    'under_review' || 'underReview' => 'قيد المعالجة',
    'contacted' => 'تم التواصل',
    'open' || 'submitted' => 'جديدة',
    _ => status ?? 'جديدة',
  };
}

String _subscriptionStatusLabel(String? status, DateTime? endDate) {
  if (status == 'paused') return 'متوقف';
  if (status == 'expired') return 'منتهي';
  if (status == 'cancelled') return 'ملغي';
  if (endDate != null && endDate.difference(DateTime.now()).inDays <= 7) {
    return 'قارب على الانتهاء';
  }
  return 'نشط';
}

String _paymentMethodLabel(String? method) {
  return switch (method) {
    'instaPay' => 'انستا باي',
    'vodafoneCash' => 'فودافون كاش',
    'bankTransfer' => 'تحويل بنكي',
    'card' => 'بطاقة',
    _ => 'نقدي',
  };
}

String _moneyText(String? amount) {
  final parsed = num.tryParse(amount ?? '');
  if (parsed == null) return amount?.isNotEmpty == true ? amount! : '٠ ج.م';
  return '${_arabicNumber(parsed)} ج.م';
}

String _timeText(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return '';
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final suffix = hour >= 12 ? 'م' : 'ص';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '${_arabicNumber(displayHour)}:${_arabicNumber(minute.toString().padLeft(2, '0'))} $suffix';
}

String _dateText(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '';
  return '${_arabicNumber(date.day)}-${_arabicNumber(date.month)}-${_arabicNumber(date.year)}';
}

DateTime? _combineDateAndTime(String date, Object? time) {
  final parts = time?.toString().split(':') ?? const [];
  if (parts.length < 2) return null;
  final parsedDate = DateTime.tryParse(date);
  if (parsedDate == null) return null;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return DateTime(
    parsedDate.year,
    parsedDate.month,
    parsedDate.day,
    hour,
    minute,
  );
}

bool _documentExpired(Map<String, dynamic> json) {
  if (json['status'] == 'expired') return true;
  final expiry = DateTime.tryParse(json['expiry_date']?.toString() ?? '');
  if (expiry == null) return false;
  return expiry.isBefore(DateTime.now());
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${_arabicNumber(diff.inMinutes)} دقيقة';
  if (diff.inHours < 24) return 'منذ ${_arabicNumber(diff.inHours)} ساعة';
  return 'منذ ${_arabicNumber(diff.inDays)} يوم';
}

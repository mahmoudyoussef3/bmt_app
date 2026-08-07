import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../domain/entities/booking_payment_verification.dart';
import '../models/booking_payment_verification_model.dart';
import 'booking_payment_verification_datasource.dart';

class SupabaseBookingPaymentVerificationDatasource
    implements BookingPaymentVerificationDatasource {
  const SupabaseBookingPaymentVerificationDatasource(this._client);

  final SupabaseClient _client;

  static const _verificationStatuses = [
    'submitted',
    'underReview',
    'approved',
    'rejected',
  ];

  @override
  Future<List<BookingPaymentVerificationModel>> fetchQueue() async {
    try {
      final response = await _client
          .from('operation_bookings')
          .select('''
            id, status, payment_method, payment_receipt_url,
            passenger_name, phone, seat, created_at, notes, timeline,
            payment_details, payment_review_status, payment_status,
            package:transport_packages(name_ar, name_en),
            payment:booking_payments(
              amount, currency, status, payment_reference, payer_phone,
              receipt_url
            ),
            trip:operation_trips(
              id, trip_date, departure_time,
              route:operation_routes(name),
              driver:drivers(full_name),
              vehicle:vehicles(plate_number)
            )
          ''')
          .inFilter('payment_status', _verificationStatuses)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _mapToModel(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<BookingPaymentVerificationModel> approve(
    String verificationId,
    String note,
  ) async {
    try {
      await _client.rpc(
        'office_approve_payment',
        params: {'p_booking_id': verificationId, 'p_note': note.trim()},
      );
      return _refetch(verificationId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<BookingPaymentVerificationModel> reject(
    String verificationId,
    String note,
  ) async {
    try {
      await _client.rpc(
        'office_reject_payment',
        params: {'p_booking_id': verificationId, 'p_reason': note.trim()},
      );
      return _refetch(verificationId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<BookingPaymentVerificationModel> requestReview(
    String verificationId,
    String note,
  ) async {
    try {
      await _client.rpc(
        'office_request_payment_review',
        params: {'p_booking_id': verificationId, 'p_note': note.trim()},
      );
      return _refetch(verificationId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<BookingPaymentVerificationModel> addNote(
    String verificationId,
    String note,
  ) async {
    try {
      final existing = await _client
          .from('operation_bookings')
          .select('notes')
          .eq('id', verificationId)
          .single();

      final currentNotes = _readStringList(existing['notes']);
      currentNotes.insert(0, note.trim());

      await _client
          .from('operation_bookings')
          .update({
            'notes': currentNotes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', verificationId);

      return _refetch(verificationId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingPaymentVerificationModel> _refetch(String bookingId) async {
    final response = await _client
        .from('operation_bookings')
        .select('''
          id, status, payment_method, payment_receipt_url,
          passenger_name, phone, seat, created_at, notes, timeline,
          payment_details, payment_review_status, payment_status,
          package:transport_packages(name_ar, name_en),
          payment:booking_payments(
            amount, currency, status, payment_reference, payer_phone,
            receipt_url
          ),
          trip:operation_trips(
            id, trip_date, departure_time,
            route:operation_routes(name),
            driver:drivers(full_name),
            vehicle:vehicles(plate_number)
          )
        ''')
        .eq('id', bookingId)
        .single();

    return _mapToModel(response);
  }

  BookingPaymentVerificationModel _mapToModel(Map<String, dynamic> json) {
    final reviewStatusStr = json['payment_status'] as String? ?? 'submitted';
    final methodStr = json['payment_method'] as String? ?? 'instapay';
    final tripJson = json['trip'] as Map<String, dynamic>?;
    final routeJson = tripJson?['route'] as Map<String, dynamic>?;
    final driverJson = tripJson?['driver'] as Map<String, dynamic>?;
    final vehicleJson = tripJson?['vehicle'] as Map<String, dynamic>?;
    final paymentDetails = json['payment_details'] as Map<String, dynamic>?;
    final payment = json['payment'] as Map<String, dynamic>?;
    final package = json['package'] as Map<String, dynamic>?;

    final notesList = _readStringList(json['notes']);
    final timelineList = _readTimeline(json['timeline']);

    return BookingPaymentVerificationModel(
      id: json['id'] as String,
      bookingId: json['id'] as String,
      customer: VerificationCustomer(
        name: json['passenger_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: '',
        profileStatus: 'عميل',
      ),
      trip: VerificationTrip(
        tripId: tripJson?['id'] as String? ?? '',
        route: routeJson?['name'] as String? ?? '',
        date: tripJson?['trip_date'] as String? ?? '',
        time: tripJson?['departure_time'] as String? ?? '',
        vehicle: vehicleJson?['plate_number'] as String? ?? '',
        driver: driverJson?['full_name'] as String? ?? '',
      ),
      selectedSeat: json['seat'] as String? ?? '',
      seatState: _mapSeatState(reviewStatusStr),
      amount:
          '${payment?['amount'] ?? paymentDetails?['amount'] ?? 0} ${payment?['currency'] ?? 'ج.م'}',
      method: _mapPaymentMethod(methodStr),
      referenceNumber:
          payment?['payment_reference']?.toString() ??
          paymentDetails?['reference']?.toString() ??
          '',
      payerPhone: payment?['payer_phone']?.toString() ?? '',
      packageName:
          package?['name_ar']?.toString() ??
          package?['name_en']?.toString() ??
          '',
      receiptTitle: _receiptTitle(methodStr),
      receiptMeta:
          (payment?['receipt_url'] ?? json['payment_receipt_url']) != null
          ? 'تم رفع الإيصال'
          : 'لم يُرفع إيصال',
      receiptUrl:
          payment?['receipt_url']?.toString() ??
          json['payment_receipt_url'] as String?,
      status: _mapVerificationStatus(reviewStatusStr),
      notes: notesList,
      history: timelineList.map((item) {
        return VerificationHistoryItem(
          title: item['action'] as String? ?? '',
          time: item['timestamp'] as String? ?? '',
          description: item['note'] as String? ?? '',
        );
      }).toList(),
    );
  }

  BookingVerificationStatus _mapVerificationStatus(String status) =>
      switch (status) {
        'approved' => BookingVerificationStatus.approved,
        'rejected' => BookingVerificationStatus.rejected,
        'underReview' || 'under_review' => BookingVerificationStatus.reviewRequested,
        _ => BookingVerificationStatus.pending,
      };

  VerificationSeatState _mapSeatState(String status) => switch (status) {
    'approved' => VerificationSeatState.permanentlyConfirmed,
    'rejected' => VerificationSeatState.released,
    _ => VerificationSeatState.temporaryReserved,
  };

  VerificationPaymentMethod _mapPaymentMethod(String method) =>
      switch (method) {
        'bank_transfer' ||
        'bankTransfer' => VerificationPaymentMethod.bankTransfer,
        'vodafone_cash' ||
        'vodafoneCash' ||
        'instapay' ||
        'instaPay' => VerificationPaymentMethod.wallet,
        'card' => VerificationPaymentMethod.card,
        _ => VerificationPaymentMethod.cash,
      };

  String _receiptTitle(String method) => switch (method) {
    'bank_transfer' || 'bankTransfer' => 'إيصال تحويل بنكي',
    'instapay' || 'instaPay' => 'إيصال إنستا باي',
    'vodafone_cash' || 'vodafoneCash' => 'إيصال فودافون كاش',
    'card' => 'إيصال بطاقة',
    _ => 'إيصال نقدي',
  };

  List<String> _readStringList(dynamic value) {
    return (value as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  List<Map<String, dynamic>> _readTimeline(dynamic value) {
    return (value as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
  }

  Exception _handleError(dynamic error) {
    // Approving a payment can settle to the wallet, and the ledger is gated on
    // `wallet`. Refusals reach here rather than the wallet datasource.
    LicensingGuard.check(error);

    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message}');
    }
    return Exception(error.toString());
  }
}

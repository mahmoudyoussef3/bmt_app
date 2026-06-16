import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking_payment_verification.dart';
import '../models/booking_payment_verification_model.dart';
import 'mock_booking_payment_verification_datasource.dart';

class SupabaseBookingPaymentVerificationDatasource
    implements BookingPaymentVerificationDatasource {
  const SupabaseBookingPaymentVerificationDatasource(this._client);

  final SupabaseClient _client;

  static const _verificationStatuses = [
    'paymentUploaded',
    'underReview',
    'requestReupload',
    'approved',
    'rejected',
  ];

  @override
  Future<List<BookingPaymentVerificationModel>> fetchQueue() async {
    try {
      final response = await _client.from('operation_bookings').select('''
            id, status, payment_method, payment_receipt_url,
            passenger_name, phone, seat, created_at, notes, timeline,
            payment_details,
            trip:operation_trips(
              id, trip_date, departure_time,
              route:operation_routes(name),
              driver:drivers(full_name),
              vehicle:vehicles(plate_number)
            )
          ''').inFilter('status', _verificationStatuses).order('created_at', ascending: false);

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
      await _client.rpc('approve_booking', params: {
        'p_booking_id': verificationId,
        'p_reviewer_name': 'خدمة العملاء',
      });
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
      await _client.rpc('reject_booking', params: {
        'p_booking_id': verificationId,
        'p_rejection_reason': note.isNotEmpty ? note : 'رُفض من قِبَل خدمة العملاء',
        'p_reviewer_name': 'خدمة العملاء',
      });
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
      await _client
          .from('operation_bookings')
          .update({'status': 'requestReupload', 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', verificationId);
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

      final currentNotes = (existing['notes'] as List?)?.map((e) => e.toString()).toList() ?? [];
      currentNotes.insert(0, note.trim());

      await _client
          .from('operation_bookings')
          .update({'notes': currentNotes})
          .eq('id', verificationId);

      return _refetch(verificationId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingPaymentVerificationModel> _refetch(String bookingId) async {
    final response = await _client.from('operation_bookings').select('''
          id, status, payment_method, payment_receipt_url,
          passenger_name, phone, seat, created_at, notes, timeline,
          payment_details,
          trip:operation_trips(
            id, trip_date, departure_time,
            route:operation_routes(name),
            driver:drivers(full_name),
            vehicle:vehicles(plate_number)
          )
        ''').eq('id', bookingId).single();

    return _mapToModel(response);
  }

  BookingPaymentVerificationModel _mapToModel(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'paymentUploaded';
    final methodStr = json['payment_method'] as String? ?? 'cash';
    final tripJson = json['trip'] as Map<String, dynamic>?;
    final routeJson = tripJson?['route'] as Map<String, dynamic>?;
    final driverJson = tripJson?['driver'] as Map<String, dynamic>?;
    final vehicleJson = tripJson?['vehicle'] as Map<String, dynamic>?;
    final paymentDetails = json['payment_details'] as Map<String, dynamic>?;

    final notesList = (json['notes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final timelineList = (json['timeline'] as List?) ?? [];

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
      seatState: _mapSeatState(statusStr),
      amount: paymentDetails?['amount'] as String? ?? '0 ج.م',
      method: _mapPaymentMethod(methodStr),
      referenceNumber: paymentDetails?['reference'] as String? ?? '',
      receiptTitle: _receiptTitle(methodStr),
      receiptMeta: json['payment_receipt_url'] != null ? 'تم رفع الإيصال' : 'لم يُرفع إيصال',
      receiptUrl: json['payment_receipt_url'] as String?,
      status: _mapVerificationStatus(statusStr),
      notes: notesList,
      history: timelineList
          .map((e) {
            final item = e as Map<String, dynamic>;
            return VerificationHistoryItem(
              title: item['action'] as String? ?? '',
              time: item['timestamp'] as String? ?? '',
              description: item['note'] as String? ?? '',
            );
          })
          .toList(),
    );
  }

  BookingVerificationStatus _mapVerificationStatus(String status) =>
      switch (status) {
        'approved' || 'confirmed' => BookingVerificationStatus.approved,
        'rejected' => BookingVerificationStatus.rejected,
        'requestReupload' => BookingVerificationStatus.reviewRequested,
        _ => BookingVerificationStatus.pending,
      };

  VerificationSeatState _mapSeatState(String status) => switch (status) {
        'approved' || 'confirmed' => VerificationSeatState.permanentlyConfirmed,
        'rejected' || 'cancelled' => VerificationSeatState.released,
        _ => VerificationSeatState.temporaryReserved,
      };

  VerificationPaymentMethod _mapPaymentMethod(String method) => switch (method) {
        'bankTransfer' => VerificationPaymentMethod.bankTransfer,
        'vodafoneCash' || 'instaPay' => VerificationPaymentMethod.wallet,
        'card' => VerificationPaymentMethod.card,
        _ => VerificationPaymentMethod.cash,
      };

  String _receiptTitle(String method) => switch (method) {
        'bankTransfer' => 'إيصال تحويل بنكي',
        'instaPay' => 'إيصال إنستا باي',
        'vodafoneCash' => 'إيصال فودافون كاش',
        'card' => 'إيصال بطاقة',
        _ => 'إيصال نقدي',
      };

  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message}');
    }
    return Exception(error.toString());
  }
}

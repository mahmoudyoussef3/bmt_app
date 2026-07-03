import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking_payment_verification.dart';
import '../models/booking_payment_verification_model.dart';
import 'booking_payment_verification_datasource.dart';

class SupabaseBookingPaymentVerificationDatasource
    implements BookingPaymentVerificationDatasource {
  const SupabaseBookingPaymentVerificationDatasource(this._client);

  final SupabaseClient _client;

  static const _verificationStatuses = [
    'pending',
    'under_review',
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
            trip:operation_trips(
              id, trip_date, departure_time,
              route:operation_routes(name),
              driver:drivers(full_name),
              vehicle:vehicles(plate_number)
            )
          ''')
          .inFilter('payment_review_status', _verificationStatuses)
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
        'approve_payment',
        params: {
          'p_booking_id': verificationId,
        },
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
        'reject_payment',
        params: {
          'p_booking_id': verificationId,
        },
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
      final existing = await _client
          .from('operation_bookings')
          .select('notes, timeline')
          .eq('id', verificationId)
          .single();
      final normalizedNote = note.trim();
      final notes = _readStringList(existing['notes']);
      if (normalizedNote.isNotEmpty) {
        notes.insert(0, normalizedNote);
      }
      final timeline = _readTimeline(existing['timeline']);
      timeline.insert(0, {
        'action': 'طلب مراجعة الدفع',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'note': normalizedNote.isEmpty
            ? 'تم طلب إعادة مراجعة أو رفع إيصال أوضح.'
            : normalizedNote,
      });

      await _client
          .from('operation_bookings')
          .update({
            'payment_review_status': 'under_review',
            'notes': notes,
            'timeline': timeline,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
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
    final reviewStatusStr = json['payment_review_status'] as String? ?? 'pending';
    final methodStr = json['payment_method'] as String? ?? 'cash';
    final tripJson = json['trip'] as Map<String, dynamic>?;
    final routeJson = tripJson?['route'] as Map<String, dynamic>?;
    final driverJson = tripJson?['driver'] as Map<String, dynamic>?;
    final vehicleJson = tripJson?['vehicle'] as Map<String, dynamic>?;
    final paymentDetails = json['payment_details'] as Map<String, dynamic>?;

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
      amount: paymentDetails?['amount'] as String? ?? '0 ج.م',
      method: _mapPaymentMethod(methodStr),
      referenceNumber: paymentDetails?['reference'] as String? ?? '',
      receiptTitle: _receiptTitle(methodStr),
      receiptMeta: json['payment_receipt_url'] != null
          ? 'تم رفع الإيصال'
          : 'لم يُرفع إيصال',
      receiptUrl: json['payment_receipt_url'] as String?,
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
        'under_review' => BookingVerificationStatus.reviewRequested,
        _ => BookingVerificationStatus.pending,
      };

  VerificationSeatState _mapSeatState(String status) => switch (status) {
    'approved' => VerificationSeatState.permanentlyConfirmed,
    'rejected' => VerificationSeatState.released,
    _ => VerificationSeatState.temporaryReserved,
  };

  VerificationPaymentMethod _mapPaymentMethod(String method) =>
      switch (method) {
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
    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message}');
    }
    return Exception(error.toString());
  }
}

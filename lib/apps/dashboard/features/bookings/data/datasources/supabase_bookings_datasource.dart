import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../../../core/query/dashboard_query_caps.dart';
import '../../domain/entities/reassignment_target.dart';
import '../models/operation_booking_model.dart';
import 'bookings_datasource.dart';

/// Reads and reviews real client bookings from `operation_bookings`, enriched
/// with the trip, route, driver, vehicle and package they reference. All state
/// transitions go through the audited SECURITY DEFINER RPCs so seat holds,
/// passenger records and notifications stay consistent — the dashboard never
/// writes booking status columns directly.
class SupabaseBookingsDatasource implements BookingsDatasource {
  final SupabaseClient _client;

  const SupabaseBookingsDatasource(this._client);

  /// The newest [DashboardQueryCaps.bookings] bookings for the office.
  ///
  /// The ordering is what makes the cap a decision rather than an accident: the
  /// rows that survive it are the most recent ones, which are the ones a queue
  /// is worked from. `BookingsLoaded.capReached` tells the board to say so.
  @override
  Future<List<OperationBookingModel>> fetchBookings() async {
    try {
      final response = await _client
          .from('operation_bookings')
          .select(OperationBookingModel.columns)
          .order('created_at', ascending: false)
          .limit(DashboardQueryCaps.bookings);

      return (response as List)
          .map((json) => OperationBookingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String? note,
  ) async {
    try {
      await _client.rpc(
        'office_approve_payment',
        params: {'p_booking_id': bookingId, 'p_note': note?.trim() ?? ''},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reason,
  ) async {
    try {
      await _client.rpc(
        'office_reject_payment',
        params: {'p_booking_id': bookingId, 'p_reason': reason.trim()},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reason,
  ) async {
    try {
      await _client.rpc(
        'office_request_payment_review',
        params: {'p_booking_id': bookingId, 'p_note': reason.trim()},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<OperationBookingModel>> bulkApprove(
    List<String> bookingIds,
    String? note,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      updated.add(await approveBooking(id, note));
    }
    return updated;
  }

  @override
  Future<List<OperationBookingModel>> bulkReject(
    List<String> bookingIds,
    String reason,
  ) async {
    final updated = <OperationBookingModel>[];
    for (final id in bookingIds) {
      updated.add(await rejectBooking(id, reason));
    }
    return updated;
  }

  @override
  Future<List<ReassignmentTarget>> fetchReassignmentTargets() async {
    try {
      final rows = await _client
          .from('operation_trips')
          .select('id, trip_date, departure_time, operation_routes(name)')
          .inFilter('status', const ['scheduled', 'open_for_booking'])
          .gte('trip_date', DateTime.now().toIso8601String().split('T').first)
          .order('trip_date')
          .order('departure_time')
          .limit(100);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        final route = map['operation_routes'] as Map<String, dynamic>?;
        return ReassignmentTarget(
          tripId: map['id'] as String,
          routeName: (route?['name'] as String?) ?? 'مسار غير معروف',
          tripDate: (map['trip_date'] as String?) ?? '',
          departureTime: (map['departure_time'] as String?) ?? '',
        );
      }).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationBookingModel> reassignBooking(
    String bookingId,
    String newTripId,
  ) async {
    try {
      await _client.rpc(
        'office_reassign_booking',
        params: {'p_booking_id': bookingId, 'p_new_trip_id': newTripId},
      );
      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// How long a burst of row changes is allowed to settle before the enriched
  /// re-read runs. Long enough to collapse a bulk approval or a coach filling
  /// up into one query, short enough that the board still reads as live.
  static const Duration realtimeSettle = Duration(milliseconds: 400);

  @override
  Stream<List<OperationBookingModel>> watchBookings() {
    // Realtime carries bare `operation_bookings` rows; the board needs the trip,
    // route, driver, vehicle and package joined onto them, which a stream cannot
    // do. So every change has to be answered by re-running the enriched select.
    //
    // Answering each change on its own turned one bulk approval of 20 bookings
    // into 20 full-table reads, and a busy sales day into a permanent one. Two
    // guards make the re-read proportional to activity instead of to row count:
    // a burst is coalesced into a single read, and while a read is in flight the
    // next is not started — it is remembered and run once the first returns.
    final controller = StreamController<List<OperationBookingModel>>();
    StreamSubscription<List<Map<String, dynamic>>>? source;
    Timer? settle;
    var reading = false;
    var pending = false;

    Future<void> read() async {
      if (reading) {
        pending = true;
        return;
      }
      reading = true;
      try {
        final bookings = await fetchBookings();
        if (!controller.isClosed) controller.add(bookings);
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      } finally {
        reading = false;
        if (pending && !controller.isClosed) {
          pending = false;
          unawaited(read());
        }
      }
    }

    controller.onListen = () {
      source = _client
          .from('operation_bookings')
          .stream(primaryKey: ['id'])
          .listen(
            (_) {
              settle?.cancel();
              settle = Timer(realtimeSettle, read);
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!controller.isClosed) controller.addError(error, stackTrace);
            },
          );
    };

    controller.onCancel = () async {
      settle?.cancel();
      await source?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  /// Prepends [note] to the booking's `notes` array.
  ///
  /// The one write in this module that is not an RPC, and it is a read-modify-
  /// write: two operators noting the same booking within the same second can
  /// lose one of the notes, because the array is rebuilt client-side rather than
  /// appended server-side. Carried over verbatim from مراجعة المدفوعات when that
  /// queue was folded into الحجوزات — folding it was not the moment to change
  /// what it does. The fix is an `office_add_booking_note` RPC that appends in
  /// one statement; see `DASHBOARD_KNOWN_ISSUES.md`.
  @override
  Future<OperationBookingModel> addNote(String bookingId, String note) async {
    try {
      final existing = await _client
          .from('operation_bookings')
          .select('notes')
          .eq('id', bookingId)
          .single();

      final notes = [
        for (final entry in (existing['notes'] as List?) ?? const [])
          if (entry != null) entry.toString(),
      ]..insert(0, note.trim());

      await _client
          .from('operation_bookings')
          .update({
            'notes': notes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId);

      return _refetch(bookingId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<OperationBookingModel> _refetch(String bookingId) async {
    final response = await _client
        .from('operation_bookings')
        .select(OperationBookingModel.columns)
        .eq('id', bookingId)
        .single();
    return OperationBookingModel.fromJson(response);
  }

  Exception _handleError(dynamic error) {
    LicensingGuard.check(error);

    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }
}

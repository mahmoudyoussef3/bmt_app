import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_seat.dart';
import '../models/trip_model.dart';
import 'trips_datasource.dart';

class SupabaseTripsDatasource implements TripsDatasource {
  final SupabaseClient _supabase;

  const SupabaseTripsDatasource(this._supabase);

  TripStatus _mapStatus(String tripStatusStr, String bookingStatusStr) {
    if (bookingStatusStr == 'cancelled') {
      return TripStatus.cancelled;
    }

    switch (tripStatusStr.toLowerCase()) {
      case 'scheduled':
      case 'open_for_booking':
        return TripStatus.upcoming;
      case 'boarding':
      case 'in_progress':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.upcoming;
    }
  }

  PaymentStatus _mapPayment(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'paid':
      case 'approved':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'rejected':
      case 'failed':
        return PaymentStatus.failed;
      case 'underreview':
      case 'under_review':
      case 'submitted':
        return PaymentStatus.underReview;
      default:
        return PaymentStatus.pending;
    }
  }

  String _reference(String id) {
    final clean = id.replaceAll('-', '');
    final take = clean.length >= 8 ? clean.substring(0, 8) : clean;
    return 'BMT-${take.toUpperCase()}';
  }

  String _initials(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.length >= 2) return trimmed.substring(0, 2).toUpperCase();
    if (trimmed.isNotEmpty) return trimmed.toUpperCase();
    return 'DP';
  }

  TripModel _mapBookingToTripModel(
    Map<String, dynamic> data, {
    List<TripSeat> seatMap = const [],
  }) {
    final tripObj = data['operation_trips'] as Map<String, dynamic>?;
    final vehicleObj = tripObj?['vehicles'] as Map<String, dynamic>?;
    final driverObj = tripObj?['drivers'] as Map<String, dynamic>?;

    final routeParts = (data['route'] as String? ?? '').split(
      RegExp(r'\s*(?:→|-)\s*'),
    );
    final pickup = routeParts.isNotEmpty ? routeParts[0] : 'Unknown';
    final destination = routeParts.length > 1 ? routeParts[1] : 'Unknown';

    final paymentDetails =
        data['payment_details'] as Map<String, dynamic>? ?? {};
    final fare = data['payment_amount']?.toString() ??
        paymentDetails['amount']?.toString() ??
        '0';
    final paymentStatusStr = paymentDetails['status']?.toString() ?? 'pending';
    final tripStatusStr = tripObj?['status']?.toString() ?? 'scheduled';
    final bookingStatusStr = data['status']?.toString() ?? 'draft';
    final dbPaymentStatus = data['payment_status']?.toString() ?? paymentStatusStr;

    return TripModel(
      id: data['id']?.toString() ?? '',
      tripId: tripObj?['id']?.toString() ?? '',
      seatMap: seatMap,
      reference:
          data['booking_number']?.toString() ??
          _reference(data['id']?.toString() ?? ''),
      status: _mapStatus(tripStatusStr, bookingStatusStr),
      pickup: pickup,
      destination: destination,
      dateLabel: data['trip_date']?.toString() ?? '',
      timeLabel: data['trip_time']?.toString() ?? '',
      driverName: driverObj?['full_name']?.toString() ?? 'Driver Pending',
      driverPhone: driverObj?['phone']?.toString() ?? 'Not available',
      driverInitials: _initials(driverObj?['full_name']?.toString()),
      driverRating: driverObj?['rating'] != null
          ? (driverObj!['rating'] as num).toDouble()
          : 0.0,
      vehicleName: vehicleObj?['brand']?.toString() ?? 'Vehicle Pending',
      vehicleType: vehicleObj?['vehicle_type']?.toString() ?? 'Vehicle',
      vehicleId: vehicleObj?['id']?.toString() ?? '',
      seats: [data['seat']?.toString() ?? 'Seat Pending'],
      paymentStatus: _mapPayment(dbPaymentStatus),
      fare: 'EGP $fare',
      cancellationReason:
          data['payment_rejection_reason']?.toString() ??
          data['rejection_reason']?.toString(),
    );
  }

  @override
  Future<List<TripModel>> getTrips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('operation_bookings')
        .select('''
          *,
          operation_trips (
            *,
            vehicles (*),
            drivers (*)
          )
        ''')
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    return response.map((e) => _mapBookingToTripModel(e)).toList();
  }

  @override
  Future<TripModel?> getTripById(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('operation_bookings')
        .select('''
          *,
          operation_trips (
            *,
            vehicles (*),
            drivers (*)
          )
        ''')
        .eq('client_id', user.id)
        .eq('id', id)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final tripId =
        (response['operation_trips'] as Map<String, dynamic>?)?['id']
            ?.toString() ??
        '';
    final seatMap = await _loadSeatMap(
      tripId: tripId,
      mySeatLabel: response['seat']?.toString() ?? '',
    );

    return _mapBookingToTripModel(response, seatMap: seatMap);
  }

  /// Loads the trip's real seat layout from `trip_seats` and flags the
  /// passenger's own seat. Best-effort: a seat-map failure must never block
  /// the whole Trip Details screen, so it degrades to an empty layout.
  Future<List<TripSeat>> _loadSeatMap({
    required String tripId,
    required String mySeatLabel,
  }) async {
    if (tripId.isEmpty) return const [];
    try {
      final rows = await _supabase
          .from('trip_seats')
          .select('seat_label, seat_row, seat_column, state')
          .eq('trip_id', tripId)
          .order('seat_row', ascending: true)
          .order('seat_column', ascending: true);

      final mine = mySeatLabel.trim().toLowerCase();
      final seats = <TripSeat>[];
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final label = row['seat_label']?.toString() ?? '';
        final number =
            int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? index + 1;
        final state = row['state']?.toString().toLowerCase() ?? 'reserved';
        final isMine =
            mine.isNotEmpty && label.trim().toLowerCase() == mine;
        seats.add(
          TripSeat(
            label: label,
            number: number,
            row: (row['seat_row'] as num?)?.toInt() ?? 0,
            column: (row['seat_column'] as num?)?.toInt() ?? 0,
            state: isMine
                ? TripSeatState.mine
                : state == 'available'
                ? TripSeatState.available
                : TripSeatState.occupied,
          ),
        );
      }
      return seats;
    } catch (_) {
      return const [];
    }
  }

  @override
  Stream<void> watchTripChanges() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    final channel = _supabase
        .channel('client_trips:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: userId,
          ),
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          callback: notify,
        )
        .subscribe();

    controller.onCancel = channel.unsubscribe;
    return controller.stream;
  }
}

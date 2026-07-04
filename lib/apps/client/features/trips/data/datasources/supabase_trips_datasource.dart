import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip.dart';
import '../models/trip_model.dart';
import 'trips_datasource.dart';

class SupabaseTripsDatasource implements TripsDatasource {
  final SupabaseClient _supabase;

  const SupabaseTripsDatasource(this._supabase);

  TripStatus _mapStatus(String tripStatusStr, String bookingStatusStr) {
    if (bookingStatusStr == 'cancelled' || bookingStatusStr == 'rejected') {
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

  PaymentStatus _mapPayment(String statusStr, String reviewStatusStr) {
    if (reviewStatusStr.toLowerCase() == 'pending' ||
        reviewStatusStr.toLowerCase() == 'under_review') {
      return PaymentStatus.underReview;
    }
    switch (statusStr.toLowerCase()) {
      case 'paid':
      case 'approved':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'rejected':
        return PaymentStatus.failed;
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

  TripModel _mapBookingToTripModel(Map<String, dynamic> data) {
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
    final fare =
        data['payment_amount']?.toString() ??
        paymentDetails['amount']?.toString() ??
        '0';
    final paymentStatusStr = paymentDetails['status']?.toString() ?? 'pending';

    final tripStatusStr = tripObj?['status']?.toString() ?? 'scheduled';
    final bookingStatusStr = data['status']?.toString() ?? 'newRequest';

    return TripModel(
      id: data['id']?.toString() ?? '',
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
      paymentStatus: _mapPayment(
        data['payment_status']?.toString() ?? paymentStatusStr,
        data['payment_review_status']?.toString() ?? 'approved',
      ),
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

    return _mapBookingToTripModel(response);
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

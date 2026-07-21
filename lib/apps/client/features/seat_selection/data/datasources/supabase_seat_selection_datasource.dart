import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/seat_option.dart';
import '../models/seat_selection_model.dart';
import 'seat_selection_datasource.dart';

class SupabaseSeatSelectionDatasource implements SeatSelectionDatasource {
  final SupabaseClient _supabase;

  const SupabaseSeatSelectionDatasource(this._supabase);

  @override
  Future<SeatSelectionModel> getSeatSelectionData(String tripId) async {
    try {
      // 1. Fetch real trip_seats for this trip.
      final seatsResponse = await _supabase
          .from('trip_seats')
          .select('id, seat_label, seat_row, seat_column, state')
          .eq('trip_id', tripId)
          .order('seat_row', ascending: true)
          .order('seat_column', ascending: true);

      final List<SeatOptionModel> seats = [];
      for (var index = 0; index < seatsResponse.length; index++) {
        final seatRecord = seatsResponse[index];
        final state = seatRecord['state']?.toString() ?? 'reserved';
        final label = seatRecord['seat_label']?.toString() ?? '';
        final seatNumber =
            int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? index + 1;
        seats.add(
          SeatOptionModel(
            id: seatRecord['id'].toString(),
            seatNumber: seatNumber,
            availability: state == 'available'
                ? SeatAvailability.available
                : SeatAvailability.reserved,
            seatLabel: label,
            row: (seatRecord['seat_row'] as num?)?.toInt() ?? 0,
            column: (seatRecord['seat_column'] as num?)?.toInt() ?? 0,
          ),
        );
      }

      // 2. Fetch trip details, vehicle details and driver.
      // `public_trips` carries sanitised `drivers` / `vehicles` jsonb in `*`.
      final tripResponse = await _supabase
          .from('public_trips')
          .select('''
          *,
          operation_routes (*),
          trip_pricing (*)
        ''')
          .eq('id', tripId)
          .maybeSingle();

      if (tripResponse == null) {
        throw Exception('Trip details could not be found.');
      }

      final vehicle = tripResponse['vehicles'] as Map<String, dynamic>? ?? {};
      final driver = tripResponse['drivers'] as Map<String, dynamic>? ?? {};
      final route =
          tripResponse['operation_routes'] as Map<String, dynamic>? ?? {};
      final pricingList = tripResponse['trip_pricing'] as List<dynamic>? ?? [];
      final pricing = pricingList.isNotEmpty
          ? pricingList.first as Map<String, dynamic>
          : <String, dynamic>{};

      if (seats.isEmpty) {
        throw Exception(
          'No seats are registered for this trip. Please contact support.',
        );
      }

      final ticketPrice = tripResponse['ticket_price'];
      final legacyPrice = pricing['one_time_price'];
      final fare = ticketPrice is num
          ? ticketPrice.toDouble()
          : legacyPrice is num
          ? legacyPrice.toDouble()
          : 0.0;
      final driverRating = driver['rating'];

      return SeatSelectionModel(
        tripId: tripId,
        seats: seats,
        pricePerSeat: fare,
        pickupPoint: route['start_city']?.toString() ?? '',
        destination: route['end_city']?.toString() ?? '',
        vehicleNumber:
            vehicle['plate_number']?.toString() ??
            vehicle['vehicle_code']?.toString() ??
            '',
        vehicleName: vehicle['brand']?.toString() ?? '',
        vehicleType: vehicle['vehicle_type']?.toString() ?? '',
        vehicleModel: vehicle['model']?.toString() ?? '',
        vehicleImageUrl: vehicle['image_url']?.toString() ?? '',
        tripDate: tripResponse['trip_date']?.toString() ?? '',
        departureTime: tripResponse['departure_time']?.toString() ?? '',
        arrivalTime: tripResponse['arrival_time']?.toString() ?? '',
        driverName: driver['full_name']?.toString() ?? '',
        driverRating: driverRating is num ? driverRating.toDouble() : 0.0,
        driverImageUrl: driver['profile_image_url']?.toString() ?? '',
      );
    } catch (error) {
      if (error is PostgrestException) {
        throw Exception('Could not load trip seats from the database.');
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final response = await _supabase.rpc(
        'lock_trip_seat',
        params: {
          'p_trip_id': tripId,
          'p_seat_id': seatId,
          'p_client_id': user.id,
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      if (e.message.contains('seat_unavailable')) {
        throw Exception('seat_unavailable');
      }
      if (e.message.contains('duplicate_active_booking')) {
        throw Exception('duplicate_active_booking');
      }
      rethrow;
    }
  }

  @override
  Future<void> releaseTripSeatLock({
    required String tripId,
    required String seatId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Best-effort compensation: the caller is already handling a failure, and
    // an expired lock is reclaimed by lock_trip_seat's self-heal anyway.
    try {
      await _supabase.rpc(
        'release_trip_seat_lock',
        params: {
          'p_trip_id': tripId,
          'p_seat_id': seatId,
          'p_client_id': user.id,
        },
      );
    } on PostgrestException {
      return;
    }
  }

  @override
  Future<Map<String, dynamic>> confirmSeatBooking(
    Map<String, dynamic> params,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final rpcParams = Map<String, dynamic>.from(params);
    rpcParams['p_client_id'] = user.id;
    // The passenger is whoever is signed in. Callers may still name them
    // explicitly (an operator booking on someone's behalf); this only fills the
    // blank so no caller has to reach into the auth session itself.
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    rpcParams['p_passenger_name'] = _orFallback(
      params['p_passenger_name'],
      metadata['full_name'],
    );
    rpcParams['p_phone'] = _orFallback(params['p_phone'], metadata['phone']);

    try {
      final response = await _supabase.rpc(
        'confirm_seat_booking_v2',
        params: rpcParams,
      );
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      if (e.message.contains('lock_expired')) {
        throw Exception('lock_expired');
      }
      if (e.message.contains('seat_not_locked') ||
          e.message.contains('seat_locked_by_other')) {
        throw Exception('seat_unavailable');
      }
      if (e.message.contains('trip_full')) {
        throw Exception('trip_full');
      }
      rethrow;
    }
  }

  @override
  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final finalParams = Map<String, dynamic>.from(params);
    finalParams['p_client_id'] = user.id;

    final response = await _supabase.rpc('book_trip_seat', params: finalParams);
    return response.toString();
  }

  @override
  Future<Map<String, dynamic>> updateExistingBookingPayment(
    Map<String, dynamic> params,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final response = await _supabase.rpc(
        'update_existing_booking_payment',
        params: params,
      );
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException {
      rethrow;
    }
  }

  String _orFallback(Object? value, Object? fallback) {
    final given = value?.toString() ?? '';
    return given.isNotEmpty ? given : (fallback?.toString() ?? '');
  }
}

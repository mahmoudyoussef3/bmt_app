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
          ),
        );
      }

      // 2. Fetch trip details, vehicle details and driver.
      final tripResponse = await _supabase
          .from('operation_trips')
          .select('''
          *,
          vehicles (*),
          drivers (*),
          operation_routes (*),
          trip_pricing (*)
        ''')
          .eq('id', tripId)
          .maybeSingle();

      if (tripResponse == null) {
        throw Exception('تعذر العثور على تفاصيل الرحلة.');
      }

      final vehicle = tripResponse['vehicles'] as Map<String, dynamic>? ?? {};
      final driver = tripResponse['drivers'] as Map<String, dynamic>? ?? {};
      final route =
          tripResponse['operation_routes'] as Map<String, dynamic>? ?? {};
      final pricingList = tripResponse['trip_pricing'] as List<dynamic>? ?? [];
      final pricing = pricingList.isNotEmpty
          ? pricingList.first as Map<String, dynamic>
          : <String, dynamic>{};

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
        tripDate: tripResponse['trip_date']?.toString() ?? '',
        departureTime: tripResponse['departure_time']?.toString() ?? '',
        arrivalTime: tripResponse['arrival_time']?.toString() ?? '',
        driverName: driver['full_name']?.toString() ?? '',
        driverRating: driverRating is num ? driverRating.toDouble() : 0.0,
      );
    } catch (error) {
      if (error is PostgrestException) {
        throw Exception('تعذر تحميل مقاعد الرحلة من قاعدة البيانات.');
      }
      rethrow;
    }
  }

  @override
  Future<String> bookTripSeat(Map<String, dynamic> params) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final finalParams = Map<String, dynamic>.from(params);
    finalParams['p_client_id'] = user.id;

    final response = await _supabase.rpc('book_trip_seat', params: finalParams);
    return response.toString();
  }
}

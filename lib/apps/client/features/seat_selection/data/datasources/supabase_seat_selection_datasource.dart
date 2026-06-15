import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/seat_option.dart';
import '../models/seat_selection_model.dart';
import 'seat_selection_datasource.dart';

class SupabaseSeatSelectionDatasource implements SeatSelectionDatasource {
  final SupabaseClient _supabase;

  const SupabaseSeatSelectionDatasource(this._supabase);

  @override
  Future<SeatSelectionModel> getSeatSelectionData(String tripId) async {
    // 1. Fetch real trip_seats for this trip
    final seatsResponse = await _supabase
        .from('trip_seats')
        .select('*')
        .eq('trip_id', tripId)
        .order('seat_number', ascending: true);

    final List<SeatOptionModel> seats = [];
    for (final seatRecord in seatsResponse) {
      final seatId = seatRecord['id'].toString();
      final state = seatRecord['state']?.toString() ?? 'available';
      final seatNumber = seatRecord['seat_number'] as int? ?? 0;
      seats.add(
        SeatOptionModel(
          id: seatId,
          seatNumber: seatNumber,
          availability: state == 'available' 
              ? SeatAvailability.available 
              : SeatAvailability.reserved,
        ),
      );
    }

    // 2. Fetch trip details, vehicle details and driver
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
      throw Exception('Trip details not found');
    }

    final vehicle = tripResponse['vehicles'] as Map<String, dynamic>? ?? {};
    final driver = tripResponse['drivers'] as Map<String, dynamic>? ?? {};
    final route = tripResponse['operation_routes'] as Map<String, dynamic>? ?? {};
    final pricingList = tripResponse['trip_pricing'] as List<dynamic>? ?? [];
    final pricing = pricingList.isNotEmpty ? pricingList.first : {};

    final pickup = route['start_point']?.toString() ?? 'Unknown';
    final destination = route['end_point']?.toString() ?? 'Unknown';
    final fare = pricing['base_price'] != null ? (pricing['base_price'] as num).toDouble() : 85.0;

    return SeatSelectionModel(
      tripId: tripId,
      seats: seats,
      pricePerSeat: fare,
      pickupPoint: pickup,
      destination: destination,
      vehicleNumber: vehicle['license_plate']?.toString() ?? 'N/A',
      vehicleName: vehicle['brand']?.toString() ?? 'Unknown Vehicle',
      vehicleType: vehicle['vehicle_type']?.toString() ?? 'Shuttle',
      vehicleModel: vehicle['model']?.toString() ?? 'Standard',
      departureTime: tripResponse['start_time']?.toString() ?? 'N/A',
      arrivalTime: tripResponse['end_time']?.toString() ?? 'N/A',
      driverName: driver['full_name']?.toString() ?? 'Unknown',
      driverRating: 5.0, // Hardcoded fallback for now
    );
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

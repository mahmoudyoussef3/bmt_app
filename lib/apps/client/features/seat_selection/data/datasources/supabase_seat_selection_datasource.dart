import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/seat_option.dart';
import '../models/seat_selection_model.dart';
import 'seat_selection_datasource.dart';

class SupabaseSeatSelectionDatasource implements SeatSelectionDatasource {
  final SupabaseClient _supabase;

  const SupabaseSeatSelectionDatasource(this._supabase);

  @override
  Future<SeatSelectionModel> getSeatSelectionData(String tripId) async {
    // 1. Fetch reserved seats for this trip
    final bookingsResponse = await _supabase
        .from('operation_bookings')
        .select('seat')
        .eq('trip_id', tripId);
        
    final List<String> reservedSeats = bookingsResponse
        .map((b) => b['seat']?.toString())
        .where((s) => s != null)
        .cast<String>()
        .toList();

    // 2. Fetch trip details, vehicle details and driver
    final tripResponse = await _supabase
        .from('operation_trips')
        .select('''
          *,
          vehicles (*),
          drivers (*)
        ''')
        .eq('id', tripId)
        .limit(1)
        .maybeSingle();

    if (tripResponse == null) {
      throw Exception('Trip details not found');
    }

    final vehicle = tripResponse['vehicles'] as Map<String, dynamic>? ?? {};
    final driver = tripResponse['drivers'] as Map<String, dynamic>? ?? {};
    final capacity = int.tryParse(vehicle['seating_capacity']?.toString() ?? '15') ?? 15;
    
    // 3. Build seat options up to capacity
    final List<SeatOptionModel> seats = [];
    for (int i = 1; i <= capacity; i++) {
      final seatId = i.toString();
      final isReserved = reservedSeats.contains(seatId) || i <= 2; // Usually 1 & 2 are for driver cabin in microbus layout
      seats.add(
        SeatOptionModel(
          id: seatId,
          availability: isReserved ? SeatAvailability.reserved : SeatAvailability.available,
        ),
      );
    }

    final routeParts = (tripResponse['route'] as String? ?? '').split(' - ');
    final pickup = routeParts.isNotEmpty ? routeParts[0] : 'Unknown';
    final destination = routeParts.length > 1 ? routeParts[1] : 'Unknown';
    final fareStr = tripResponse['fare']?.toString() ?? '85';
    final fare = double.tryParse(fareStr) ?? 85.0;

    return SeatSelectionModel(
      seats: seats,
      pricePerSeat: fare,
      pickupPoint: pickup,
      destination: destination,
      vehicleNumber: vehicle['license_plate']?.toString() ?? 'N/A',
      vehicleName: vehicle['brand']?.toString() ?? 'Unknown Vehicle',
      vehicleType: vehicle['vehicle_type']?.toString() ?? 'Shuttle',
      vehicleModel: vehicle['model']?.toString() ?? 'Standard',
      departureTime: tripResponse['trip_time']?.toString() ?? 'N/A',
      arrivalTime: 'N/A', // You could calculate this if needed
      driverName: driver['full_name']?.toString() ?? 'Unknown',
      driverRating: 4.8, // Fallback as actual rating calculation isn't in drivers table by default
    );
  }
}

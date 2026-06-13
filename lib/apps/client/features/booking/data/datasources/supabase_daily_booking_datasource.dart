import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/daily_booking_data.dart';
import 'daily_booking_datasource.dart';

class SupabaseDailyBookingDatasource implements DailyBookingDatasource {
  final SupabaseClient _supabase;

  const SupabaseDailyBookingDatasource(this._supabase);

  @override
  Future<BookingHubData> getBookingHubData() async {
    final routesResponse = await _supabase.from('routes').select('id');
    final packagesResponse = await _supabase.from('packages').select('id');
    final tripsResponse = await _supabase.from('operation_trips').select('id').eq('status', 'scheduled');
    
    final user = _supabase.auth.currentUser;
    List<dynamic> upcomingBookings = [];
    if (user != null) {
      upcomingBookings = await _supabase
          .from('operation_bookings')
          .select('id')
          .eq('client_id', user.id)
          .inFilter('status', ['newRequest', 'approved', 'active']);
    }

    return BookingHubData(
      todayRoutes: '${routesResponse.length} routes',
      monthPlans: '${packagesResponse.length} plans',
      activeTrips: tripsResponse.length.toString(),
      upcomingBookings: upcomingBookings.length.toString(),
      reservedSeats: '0', // Need more robust logic to calculate total seats reserved by user
    );
  }

  @override
  Future<DailyBookingData> getDailyBookingData() async {
    final tripsResponse = await _supabase
        .from('operation_trips')
        .select('''
          *,
          vehicles (vehicle_type, capacity),
          drivers (full_name)
        ''')
        .eq('status', 'scheduled');

    final routesResponse = await _supabase.from('routes').select('pickup, destination').eq('status', 'active');

    final distinctPickups = routesResponse.map((e) => e['pickup'].toString()).toSet().toList();
    final distinctDestinations = routesResponse.map((e) => e['destination'].toString()).toSet().toList();

    final vehicles = tripsResponse.map((data) {
      final vehicle = data['vehicles'] as Map<String, dynamic>?;
      final driver = data['drivers'] as Map<String, dynamic>?;
      final capacity = vehicle?['capacity'] as int? ?? 14;
      final passengers = data['passenger_count'] as int? ?? 0;

      return DailyBookingVehicle(
        id: data['vehicle_id']?.toString() ?? '',
        driver: driver?['full_name']?.toString() ?? 'Unknown Driver',
        time: data['trip_date']?.toString() ?? '',
        seatsLeft: capacity - passengers,
        occupancy: capacity > 0 ? passengers / capacity : 0,
      );
    }).toList();

    return DailyBookingData(
      pickupPoints: distinctPickups.isNotEmpty ? distinctPickups : ['Banha Station', 'Banha Center'],
      destinations: distinctDestinations.isNotEmpty ? distinctDestinations : ['Smart Village', 'Nasr City'],
      arrivalTimes: ['8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM'], // Stubbed, format properly in production
      vehicles: vehicles,
    );
  }
}

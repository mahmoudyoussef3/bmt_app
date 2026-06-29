import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/daily_booking_data.dart';
import 'daily_booking_datasource.dart';

class SupabaseDailyBookingDatasource implements DailyBookingDatasource {
  final SupabaseClient _supabase;

  const SupabaseDailyBookingDatasource(this._supabase);

  @override
  Future<BookingHubData> getBookingHubData() async {
    final routesResponse = await _supabase
        .from('operation_routes')
        .select('id');
    final packagesResponse = await _supabase.from('packages').select('id');
    final tripsResponse = await _supabase
        .from('operation_trips')
        .select('id')
        .eq('status', 'open_for_booking');

    final user = _supabase.auth.currentUser;
    List<dynamic> upcomingBookings = [];
    int reservedSeats = 0;
    if (user != null) {
      upcomingBookings = await _supabase
          .from('operation_bookings')
          .select('id, seats_count')
          .eq('client_id', user.id)
          .inFilter('status', ['newRequest', 'approved', 'active']);
      reservedSeats = upcomingBookings.fold<int>(
        0,
        (sum, b) => sum + ((b['seats_count'] as int?) ?? 1),
      );
    }

    return BookingHubData(
      todayRoutes: '${routesResponse.length} routes',
      monthPlans: '${packagesResponse.length} plans',
      activeTrips: tripsResponse.length.toString(),
      upcomingBookings: upcomingBookings.length.toString(),
      reservedSeats: reservedSeats.toString(),
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
        .inFilter('status', ['open_for_booking', 'boarding']);

    final routesResponse = await _supabase
        .from('operation_routes')
        .select('start_city, end_city')
        .eq('status', 'active');

    final distinctPickups = routesResponse
        .map((e) => e['start_city'].toString())
        .toSet()
        .toList();
    final distinctDestinations = routesResponse
        .map((e) => e['end_city'].toString())
        .toSet()
        .toList();

    final vehicles = tripsResponse.map((data) {
      final vehicle = data['vehicles'] as Map<String, dynamic>?;
      final driver = data['drivers'] as Map<String, dynamic>?;
      final capacity = vehicle?['capacity'] as int? ?? 14;
      final passengers = data['passenger_count'] as int? ?? 0;

      return DailyBookingVehicle(
        id: data['id']?.toString() ?? '',
        driver: driver?['full_name']?.toString() ?? 'Unknown Driver',
        time: data['departure_time']?.toString() ?? '',
        seatsLeft: capacity - passengers,
        occupancy: capacity > 0 ? passengers / capacity : 0,
      );
    }).toList();

    final distinctArrivalTimes = tripsResponse
        .map((t) => t['arrival_time']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return DailyBookingData(
      pickupPoints: distinctPickups.isNotEmpty ? distinctPickups : [],
      destinations: distinctDestinations.isNotEmpty ? distinctDestinations : [],
      arrivalTimes: distinctArrivalTimes,
      vehicles: vehicles,
    );
  }
}

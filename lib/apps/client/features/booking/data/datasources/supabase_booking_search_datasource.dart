import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_search_query.dart';
import '../models/booking_option_model.dart';
import 'booking_search_datasource.dart';

class SupabaseBookingSearchDatasource implements BookingSearchDatasource {
  final SupabaseClient _supabase;

  const SupabaseBookingSearchDatasource(this._supabase);

  @override
  Future<List<RouteOptionModel>> getRoutes(BookingSearchQuery query) async {
    final pickup = query.pickup.isEmpty ? 'Banha Center' : query.pickup;
    final dest = query.destination.isEmpty ? 'Smart Village' : query.destination;

    final response = await _supabase
        .from('routes')
        .select()
        .eq('pickup', pickup)
        .eq('destination', dest)
        .eq('status', 'active');

    return response.map((data) {
      return RouteOptionModel(
        id: data['id']?.toString() ?? '',
        pickup: data['pickup']?.toString() ?? '',
        destination: data['destination']?.toString() ?? '',
        duration: data['duration']?.toString() ?? '',
        availableSeats: 14, // Real implementation requires joined query from operation_trips
        startingPrice: 'EGP ${data['starting_price']}',
        isFastest: data['is_popular'] == true,
      );
    }).toList();
  }

  @override
  Future<List<PopularRouteListModel>> getPopularRoutes() async {
    final response = await _supabase
        .from('routes')
        .select()
        .eq('status', 'active')
        .eq('is_popular', true);

    return response.map((data) {
      return PopularRouteListModel(
        routeName: '${data['pickup']} — ${data['destination']}',
        dailyTrips: 15, // Can be counted from trips table
        averageDuration: data['duration']?.toString() ?? '',
        startingPrice: 'EGP ${data['starting_price']}',
        pickup: data['pickup']?.toString() ?? '',
        destination: data['destination']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<List<AvailableTripModel>> getAvailableTrips(
    BookingSearchQuery query,
  ) async {
    final response = await _supabase
        .from('operation_trips')
        .select('''
          *,
          vehicles (vehicle_type, capacity),
          drivers (full_name)
        ''')
        .eq('status', 'scheduled');

    return response.map((data) {
      final vehicle = data['vehicles'] as Map<String, dynamic>?;
      final driver = data['drivers'] as Map<String, dynamic>?;
      final capacity = vehicle?['capacity'] as int? ?? 14;
      final passengers = data['passenger_count'] as int? ?? 0;

      return AvailableTripModel(
        vehicleId: data['vehicle_id']?.toString() ?? '',
        vehicleType: vehicle?['vehicle_type']?.toString() ?? 'Standard Shuttle',
        driverName: driver?['full_name']?.toString() ?? 'Unknown Driver',
        estimatedArrival: data['trip_date']?.toString() ?? '', // Formatting needed
        routeDuration: '45 min', // Ideally joined from routes
        availableSeats: capacity - passengers,
        startingPrice: 'EGP 85', // Ideally joined from routes
      );
    }).toList();
  }

  @override
  Future<List<MapPinOptionModel>> getPickupMapPins() async {
    final response = await _supabase
        .from('routes')
        .select('pickup')
        .eq('status', 'active');
        
    final distinctPickups = response.map((e) => e['pickup'].toString()).toSet();
    
    return distinctPickups.map((pickup) {
      return MapPinOptionModel(
        label: pickup,
        subtitle: 'Pickup point',
        x: 0.5, // Dummy coordinate
        y: 0.5,
      );
    }).toList();
  }

  @override
  Future<List<MapPinOptionModel>> getDestinationMapPins() async {
    final response = await _supabase
        .from('routes')
        .select('destination')
        .eq('status', 'active');
        
    final distinctDestinations = response.map((e) => e['destination'].toString()).toSet();
    
    return distinctDestinations.map((dest) {
      return MapPinOptionModel(
        label: dest,
        subtitle: 'Drop-off point',
        x: 0.5, // Dummy coordinate
        y: 0.5,
      );
    }).toList();
  }
}

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
        .from('operation_routes')
        .select('*, route_stations(name, sort_order)')
        .eq('status', 'active');

    final List<RouteOptionModel> matchedRoutes = [];

    for (var data in response) {
      final stations = (data['route_stations'] as List<dynamic>?) ?? [];
      
      // Check if this route connects the pickup and dest
      bool hasPickup = false;
      bool hasDest = false;
      int pickupOrder = -1;
      int destOrder = -1;

      for (var station in stations) {
        final stationName = station['name']?.toString() ?? '';
        final sortOrder = station['sort_order'] as int? ?? 0;
        
        if (stationName.toLowerCase() == pickup.toLowerCase() || data['start_city'].toString().toLowerCase() == pickup.toLowerCase()) {
          hasPickup = true;
          pickupOrder = sortOrder;
        }
        if (stationName.toLowerCase() == dest.toLowerCase() || data['end_city'].toString().toLowerCase() == dest.toLowerCase()) {
          hasDest = true;
          destOrder = sortOrder;
        }
      }

      // If we don't have explicit stations, fallback to checking start_city / end_city directly
      if (stations.isEmpty) {
        if (data['start_city'].toString().toLowerCase() == pickup.toLowerCase()) hasPickup = true;
        if (data['end_city'].toString().toLowerCase() == dest.toLowerCase()) hasDest = true;
        pickupOrder = 0;
        destOrder = 1;
      }

      // Valid if it has both and pickup comes before dest (or if no order is defined, just has both)
      if (hasPickup && hasDest && pickupOrder <= destOrder) {
        matchedRoutes.add(RouteOptionModel(
          id: data['id']?.toString() ?? '',
          pickup: pickup,
          destination: dest,
          duration: data['duration']?.toString() ?? 'N/A',
          availableSeats: 14, // Real implementation requires joined query from operation_trips
          startingPrice: 'Varies', // Real implementation from trip_pricing
          isFastest: true,
        ));
      }
    }

    return matchedRoutes;
  }

  @override
  Future<List<PopularRouteListModel>> getPopularRoutes() async {
    final response = await _supabase
        .from('operation_routes')
        .select('*, route_stations(name)')
        .eq('status', 'active')
        .limit(10); // Assume first 10 active are popular for now

    return response.map((data) {
      return PopularRouteListModel(
        routeName: data['name']?.toString() ?? '${data['start_city']} — ${data['end_city']}',
        dailyTrips: 15, // Can be counted from trips table
        averageDuration: data['duration']?.toString() ?? 'N/A',
        startingPrice: 'Varies',
        pickup: data['start_city']?.toString() ?? '',
        destination: data['end_city']?.toString() ?? '',
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
          drivers (full_name),
          operation_routes (duration)
        ''')
        .eq('status', 'scheduled');

    return response.map((data) {
      final vehicle = data['vehicles'] as Map<String, dynamic>?;
      final driver = data['drivers'] as Map<String, dynamic>?;
      final route = data['operation_routes'] as Map<String, dynamic>?;
      final capacity = vehicle?['capacity'] as int? ?? 14;
      final passengers = data['passenger_count'] as int? ?? 0;

      return AvailableTripModel(
        vehicleId: data['vehicle_id']?.toString() ?? '',
        vehicleType: vehicle?['vehicle_type']?.toString() ?? 'Standard Shuttle',
        driverName: driver?['full_name']?.toString() ?? 'Unknown Driver',
        estimatedArrival: data['trip_date']?.toString() ?? '', // Formatting needed
        routeDuration: route?['duration']?.toString() ?? '45 min',
        availableSeats: capacity - passengers,
        startingPrice: 'Varies', 
      );
    }).toList();
  }

  @override
  Future<List<MapPinOptionModel>> getPickupMapPins() async {
    final response = await _supabase
        .from('route_stations')
        .select('name, operation_routes!inner(status)')
        .eq('operation_routes.status', 'active');
        
    final distinctPickups = response.map((e) => e['name'].toString()).toSet();
    
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
        .from('route_stations')
        .select('name, operation_routes!inner(status)')
        .eq('operation_routes.status', 'active');
        
    final distinctDestinations = response.map((e) => e['name'].toString()).toSet();
    
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

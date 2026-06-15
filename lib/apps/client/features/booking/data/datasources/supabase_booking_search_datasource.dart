import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_search_query.dart';
import '../models/booking_option_model.dart';
import 'booking_search_datasource.dart';

class SupabaseBookingSearchDatasource implements BookingSearchDatasource {
  final SupabaseClient _supabase;

  const SupabaseBookingSearchDatasource(this._supabase);

  @override
  Future<List<RouteOptionModel>> getRoutes(BookingSearchQuery query) async {
    final pickup = query.pickup.isEmpty ? 'Cairo' : query.pickup;
    final dest = query.destination.isEmpty ? 'Alexandria' : query.destination;

    final response = await _supabase
        .from('operation_routes')
        .select('*, route_stations(name, sort_order)')
        .eq('status', 'active');

    final List<RouteOptionModel> matchedRoutes = [];

    for (var data in response) {
      final stations = (data['route_stations'] as List<dynamic>?) ?? [];
      final basePrice = 'Varies';
      
      bool hasPickup = false;
      bool hasDest = false;
      int pickupOrder = -1;
      int destOrder = -1;

      for (var station in stations) {
        final stationName = station['name']?.toString() ?? '';
        final sortOrder = station['sort_order'] as int? ?? 0;
        
        if (stationName.toLowerCase() == pickup.toLowerCase() || data['start_point'].toString().toLowerCase() == pickup.toLowerCase()) {
          hasPickup = true;
          pickupOrder = sortOrder;
        }
        if (stationName.toLowerCase() == dest.toLowerCase() || data['end_point'].toString().toLowerCase() == dest.toLowerCase()) {
          hasDest = true;
          destOrder = sortOrder;
        }
      }

      if (stations.isEmpty) {
        if (data['start_point'].toString().toLowerCase() == pickup.toLowerCase()) hasPickup = true;
        if (data['end_point'].toString().toLowerCase() == dest.toLowerCase()) hasDest = true;
        pickupOrder = 0;
        destOrder = 1;
      }

      if (hasPickup && hasDest && pickupOrder <= destOrder) {
        matchedRoutes.add(RouteOptionModel(
          id: data['id']?.toString() ?? '',
          pickup: pickup,
          destination: dest,
          duration: data['estimated_time']?.toString() ?? 'N/A',
          availableSeats: 14, // Real count needs to come from trips
          startingPrice: basePrice,
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
        .select('*, route_stations(name, sort_order)')
        .eq('status', 'active')
        .limit(10);

    return response.map((data) {
      final basePrice = 'Varies';

      return PopularRouteListModel(
        routeName: data['route_code']?.toString() ?? '${data['start_point']} — ${data['end_point']}',
        dailyTrips: 15, // Can be counted dynamically if needed
        averageDuration: data['estimated_time']?.toString() ?? 'N/A',
        startingPrice: basePrice,
        pickup: data['start_point']?.toString() ?? '',
        destination: data['end_point']?.toString() ?? '',
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
          operation_routes(estimated_time),
          trip_pricing(base_price, currency)
        ''')
        .eq('status', 'active')
        .limit(5);

    return response.map((data) {
      final vehicle = (data['vehicles'] as Map<String, dynamic>?) ?? {};
      final driver = (data['drivers'] as Map<String, dynamic>?) ?? {};
      final route = (data['operation_routes'] as Map<String, dynamic>?) ?? {};
      final pricing = (data['trip_pricing'] as List<dynamic>?) ?? [];
      
      final capacity = vehicle['capacity'] as int? ?? 14;
      final passengerCount = data['passenger_count'] as int? ?? 0;
      final basePrice = pricing.isNotEmpty ? '${pricing[0]['currency']} ${pricing[0]['base_price']}' : 'Varies';

      return AvailableTripModel(
        vehicleId: data['id']?.toString() ?? '', // Actually trip_id
        vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
        driverName: driver['full_name']?.toString() ?? 'Driver',
        estimatedArrival: data['end_time']?.toString() ?? 'N/A',
        routeDuration: route['estimated_time']?.toString() ?? 'N/A',
        availableSeats: capacity - passengerCount,
        startingPrice: basePrice,
      );
    }).toList();
  }

  @override
  Future<List<MapPinOptionModel>> getPickupMapPins() async {
    final response = await _supabase
        .from('route_stations')
        .select('station_name, operation_routes!inner(status)')
        .eq('operation_routes.status', 'active');
        
    final distinctPickups = response.map((e) => e['station_name'].toString()).toSet();
    
    return distinctPickups.map((pickup) {
      return MapPinOptionModel(
        label: pickup,
        subtitle: 'Terminal',
        x: 30.0,
        y: 31.0,
      );
    }).toList();
  }

  @override
  Future<List<MapPinOptionModel>> getDestinationMapPins() async {
    final response = await _supabase
        .from('route_stations')
        .select()
        .limit(10);

    return response.map((data) {
      return MapPinOptionModel(
        label: data['station_name']?.toString() ?? 'Station',
        subtitle: 'Terminal',
        x: data['latitude'] != null ? (data['latitude'] as num).toDouble() : 30.0,
        y: data['longitude'] != null ? (data['longitude'] as num).toDouble() : 31.0,
      );
    }).toList();
  }
}

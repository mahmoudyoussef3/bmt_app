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
        .select(
          '*, route_stations(name, sort_order, latitude, longitude, pickup_allowed, dropoff_allowed)',
        )
        .eq('status', 'active');

    final List<RouteOptionModel> matchedRoutes = [];

    for (var data in response) {
      final stations = (data['route_stations'] as List<dynamic>?) ?? [];
      final trips = await _supabase
          .from('operation_trips')
          .select(
            'capacity, passenger_count, booked_seats, ticket_price, currency',
          )
          .eq('route_id', data['id'])
          .eq('status', 'scheduled');
      final availableSeats = trips.fold<int>(0, (sum, trip) {
        final capacity = trip['capacity'] as int? ?? 0;
        final used =
            trip['passenger_count'] as int? ??
            trip['booked_seats'] as int? ??
            0;
        final remaining = capacity - used;
        return sum + remaining.clamp(0, capacity).toInt();
      });
      final firstTrip = trips.isNotEmpty ? trips.first : null;
      final basePrice = firstTrip == null
          ? 'غير متاح'
          : '${firstTrip['currency'] ?? 'ج.م'} ${firstTrip['ticket_price'] ?? 0}';
      final routePoints = _mapRoutePoints(
        stations,
        startCity: data['start_city']?.toString() ?? '',
        endCity: data['end_city']?.toString() ?? '',
      );

      bool hasPickup = false;
      bool hasDest = false;
      int pickupOrder = -1;
      int destOrder = -1;

      for (var station in stations) {
        final stationName = station['name']?.toString() ?? '';
        final sortOrder = station['sort_order'] as int? ?? 0;

        final pickupAllowed = station['pickup_allowed'] as bool? ?? true;
        final dropoffAllowed = station['dropoff_allowed'] as bool? ?? true;
        if (pickupAllowed &&
            (stationName.toLowerCase() == pickup.toLowerCase() ||
                data['start_city'].toString().toLowerCase() ==
                    pickup.toLowerCase())) {
          hasPickup = true;
          pickupOrder = sortOrder;
        }
        if (dropoffAllowed &&
            (stationName.toLowerCase() == dest.toLowerCase() ||
                data['end_city'].toString().toLowerCase() ==
                    dest.toLowerCase())) {
          hasDest = true;
          destOrder = sortOrder;
        }
      }

      if (stations.isEmpty) {
        if (data['start_city'].toString().toLowerCase() ==
            pickup.toLowerCase()) {
          hasPickup = true;
        }
        if (data['end_city'].toString().toLowerCase() == dest.toLowerCase()) {
          hasDest = true;
        }
        pickupOrder = 0;
        destOrder = 1;
      }

      if (hasPickup && hasDest && pickupOrder <= destOrder) {
        matchedRoutes.add(
          RouteOptionModel(
            id: data['id']?.toString() ?? '',
            pickup: pickup,
            destination: dest,
            duration: data['duration']?.toString() ?? 'N/A',
            availableSeats: availableSeats,
            startingPrice: basePrice,
            points: routePoints,
            isFastest: true,
          ),
        );
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

    final today = DateTime.now().toIso8601String().split('T').first;
    final trips = await _supabase
        .from('operation_trips')
        .select('route_id, ticket_price, currency')
        .gte('trip_date', today)
        .eq('status', 'scheduled');

    return response.map((data) {
      final routeTrips = trips
          .where((trip) => trip['route_id'] == data['id'])
          .toList();
      final firstTrip = routeTrips.isNotEmpty ? routeTrips.first : null;
      final basePrice = firstTrip == null
          ? 'غير متاح'
          : '${firstTrip['currency'] ?? 'ج.م'} ${firstTrip['ticket_price'] ?? 0}';

      return PopularRouteListModel(
        routeName:
            data['name']?.toString() ??
            '${data['start_city']} — ${data['end_city']}',
        dailyTrips: routeTrips.length,
        averageDuration: data['duration']?.toString() ?? 'N/A',
        startingPrice: basePrice,
        pickup: data['start_city']?.toString() ?? '',
        destination: data['end_city']?.toString() ?? '',
      );
    }).toList();
  }

  List<RoutePointModel> _mapRoutePoints(
    List<dynamic> stations, {
    required String startCity,
    required String endCity,
  }) {
    final points =
        stations
            .whereType<Map<String, dynamic>>()
            .map((station) {
              final name = station['name']?.toString().trim() ?? '';
              if (name.isEmpty) return null;
              return RoutePointModel(
                name: name,
                order: station['sort_order'] as int? ?? 0,
                latitude: _toDouble(station['latitude']),
                longitude: _toDouble(station['longitude']),
              );
            })
            .whereType<RoutePointModel>()
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    if (points.isNotEmpty) return points;

    return [
      if (startCity.isNotEmpty) RoutePointModel(name: startCity, order: 1),
      if (endCity.isNotEmpty) RoutePointModel(name: endCity, order: 2),
    ];
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
          operation_routes(id, start_city, end_city, duration),
          trip_pricing(one_time_price, currency)
        ''')
        .eq('status', 'scheduled')
        .limit(5);

    return response.map((data) {
      final vehicle = (data['vehicles'] as Map<String, dynamic>?) ?? {};
      final driver = (data['drivers'] as Map<String, dynamic>?) ?? {};
      final route = (data['operation_routes'] as Map<String, dynamic>?) ?? {};

      final capacity = vehicle['capacity'] as int? ?? 14;
      final passengerCount = data['passenger_count'] as int? ?? 0;
      final basePrice =
          '${data['currency'] ?? 'ج.م'} ${data['ticket_price'] ?? 0}';

      return AvailableTripModel(
        vehicleId: data['id']?.toString() ?? '', // Actually trip_id
        vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
        driverName: driver['full_name']?.toString() ?? 'Driver',
        estimatedArrival: data['arrival_time']?.toString() ?? 'N/A',
        routeDuration: route['duration']?.toString() ?? 'N/A',
        availableSeats: capacity - passengerCount,
        startingPrice: basePrice,
      );
    }).toList();
  }

  @override
  Future<List<MapPinOptionModel>> getPickupMapPins() async {
    final response = await _supabase
        .from('route_stations')
        .select('name, operation_routes!inner(status)')
        .eq('operation_routes.status', 'active')
        .eq('pickup_allowed', true);

    final distinctPickups = response.map((e) => e['name'].toString()).toSet();

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
        .eq('dropoff_allowed', true)
        .limit(10);

    return response.map((data) {
      return MapPinOptionModel(
        label: data['name']?.toString() ?? 'Station',
        subtitle: 'Terminal',
        x: data['latitude'] != null
            ? (data['latitude'] as num).toDouble()
            : 30.0,
        y: data['longitude'] != null
            ? (data['longitude'] as num).toDouble()
            : 31.0,
      );
    }).toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_search_query.dart';
import '../models/booking_option_model.dart';
import 'booking_search_datasource.dart';

class SupabaseBookingSearchDatasource implements BookingSearchDatasource {
  final SupabaseClient _supabase;

  const SupabaseBookingSearchDatasource(this._supabase);

  @override
  Future<List<RouteOptionModel>> getRoutes(BookingSearchQuery query) async {
    var routesQuery = _supabase
        .from('operation_routes')
        .select()
        .eq('status', 'active');
    if (query.routeId != null && query.routeId!.isNotEmpty) {
      routesQuery = routesQuery.eq('id', query.routeId!);
    }
    final response = await routesQuery;

    final routeIds = response
        .map((route) => route['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final stationsResponse = routeIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
              .from('route_stations')
              .select(
                'route_id, name, sort_order, latitude, longitude, pickup_allowed, dropoff_allowed',
              )
              .inFilter('route_id', routeIds)
              .order('sort_order');
    final stationsByRouteId = <String, List<dynamic>>{};
    for (final station in stationsResponse) {
      final routeId = station['route_id']?.toString();
      if (routeId == null || routeId.isEmpty) continue;
      stationsByRouteId.putIfAbsent(routeId, () => []).add(station);
    }

    final List<RouteOptionModel> matchedRoutes = [];

    for (var data in response) {
      final routeId = data['id']?.toString() ?? '';
      final stations = stationsByRouteId[routeId] ?? const <dynamic>[];
      final startCity = data['start_city']?.toString() ?? '';
      final endCity = data['end_city']?.toString() ?? '';
      final pickup = query.pickup.isEmpty ? startCity : query.pickup;
      final dest = query.destination.isEmpty ? endCity : query.destination;
      final trips = await _supabase
          .from('operation_trips')
          .select('''
            id, departure_time, arrival_time, capacity, passenger_count, booked_seats,
            ticket_price, currency, status,
            vehicles(vehicle_type)
          ''')
          .eq('route_id', data['id'])
          .inFilter('status', ['scheduled', 'openForBooking']);
      final availableSeats = trips.fold<int>(0, (sum, trip) {
        final capacity = trip['capacity'] as int? ?? 0;
        final used =
            trip['passenger_count'] as int? ??
            trip['booked_seats'] as int? ??
            0;
        final remaining = capacity - used;
        return sum + remaining.clamp(0, capacity).toInt();
      });
      final pricedTrips = trips
          .where((trip) => trip['ticket_price'] != null)
          .toList();
      pricedTrips.sort((a, b) {
        final aPrice =
            (a['ticket_price'] as num?)?.toDouble() ?? double.infinity;
        final bPrice =
            (b['ticket_price'] as num?)?.toDouble() ?? double.infinity;
        return aPrice.compareTo(bPrice);
      });
      final firstPricedTrip = pricedTrips.isNotEmpty ? pricedTrips.first : null;
      final currency = firstPricedTrip?['currency']?.toString() ?? 'EGP';
      final basePrice = firstPricedTrip == null
          ? 'Price pending'
          : '$currency ${firstPricedTrip['ticket_price'] ?? 0}';
      final priceRange = _priceRangeLabel(pricedTrips, currency: currency);
      final availableTrips = trips.map((trip) {
        final capacity = trip['capacity'] as int? ?? 0;
        final used =
            trip['passenger_count'] as int? ??
            trip['booked_seats'] as int? ??
            0;
        final remaining = capacity - used;
        final vehicle = trip['vehicles'] as Map<String, dynamic>? ?? {};
        final tripCurrency = trip['currency']?.toString() ?? currency;
        final tripPrice = trip['ticket_price'];

        return RouteTripOptionModel(
          id: trip['id']?.toString() ?? '',
          departureTime: trip['departure_time']?.toString() ?? 'Not set',
          arrivalTime: trip['arrival_time']?.toString() ?? 'Not set',
          availableSeats: remaining.clamp(0, capacity).toInt(),
          vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
          price: tripPrice == null
              ? 'Price pending'
              : '$tripCurrency $tripPrice',
        );
      }).toList();
      final routePoints = _mapRoutePoints(
        stations,
        startCity: startCity,
        endCity: endCity,
      );

      final pickupOrder = _pointOrder(
        pickup,
        stations: stations,
        startCity: startCity,
        endCity: endCity,
        checkPickup: true,
      );
      final destOrder = _pointOrder(
        dest,
        stations: stations,
        startCity: startCity,
        endCity: endCity,
        checkPickup: false,
      );
      final matchesRequestedRoute =
          query.routeId != null && query.routeId!.isNotEmpty;

      if (matchesRequestedRoute ||
          (pickupOrder != null &&
              destOrder != null &&
              pickupOrder <= destOrder)) {
        matchedRoutes.add(
          RouteOptionModel(
            id: routeId,
            routeName: data['name']?.toString().trim().isNotEmpty == true
                ? data['name'].toString()
                : '$startCity - $endCity',
            pickup: pickup,
            destination: dest,
            distance: data['distance']?.toString() ?? 'Not set',
            duration: data['duration']?.toString() ?? 'N/A',
            availableSeats: availableSeats,
            startingPrice: basePrice,
            priceRange: priceRange,
            availableTrips: availableTrips,
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
        .inFilter('status', ['scheduled', 'openForBooking']);

    return response.map((data) {
      final routeTrips = trips
          .where((trip) => trip['route_id'] == data['id'])
          .toList();
      final pricedTrips = routeTrips
          .where((trip) => trip['ticket_price'] != null)
          .toList();
      pricedTrips.sort((a, b) {
        final aPrice =
            (a['ticket_price'] as num?)?.toDouble() ?? double.infinity;
        final bPrice =
            (b['ticket_price'] as num?)?.toDouble() ?? double.infinity;
        return aPrice.compareTo(bPrice);
      });
      final firstTrip = pricedTrips.isNotEmpty ? pricedTrips.first : null;
      final basePrice = firstTrip == null
          ? 'Price pending'
          : '${firstTrip['currency'] ?? 'EGP'} ${firstTrip['ticket_price'] ?? 0}';

      return PopularRouteListModel(
        id: data['id']?.toString() ?? '',
        routeName:
            data['name']?.toString() ??
            '${data['start_city']} — ${data['end_city']}',
        dailyTrips: routeTrips.length,
        averageDuration: data['duration']?.toString() ?? 'N/A',
        startingPrice: basePrice,
        pickup: data['start_city']?.toString() ?? '',
        destination: data['end_city']?.toString() ?? '',
        distance: data['distance']?.toString() ?? 'Not set',
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
                pickupAllowed: station['pickup_allowed'] as bool? ?? true,
                dropoffAllowed: station['dropoff_allowed'] as bool? ?? true,
                latitude: _toDouble(station['latitude']),
                longitude: _toDouble(station['longitude']),
              );
            })
            .whereType<RoutePointModel>()
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    if (points.isNotEmpty) return points;

    return [
      if (startCity.isNotEmpty)
        RoutePointModel(
          name: startCity,
          order: 1,
          pickupAllowed: true,
          dropoffAllowed: false,
        ),
      if (endCity.isNotEmpty)
        RoutePointModel(
          name: endCity,
          order: 2,
          pickupAllowed: false,
          dropoffAllowed: true,
        ),
    ];
  }

  int? _pointOrder(
    String value, {
    required List<dynamic> stations,
    required String startCity,
    required String endCity,
    required bool checkPickup,
  }) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    if (startCity.trim().toLowerCase() == normalized) {
      return stations.isEmpty ? 0 : _stationOrder(stations.first);
    }
    if (endCity.trim().toLowerCase() == normalized) {
      return stations.isEmpty ? 1 : _stationOrder(stations.last);
    }

    for (final station in stations) {
      final stationName =
          station['name']?.toString().trim().toLowerCase() ?? '';
      if (stationName != normalized) continue;
      final allowed = checkPickup
          ? station['pickup_allowed'] as bool? ?? true
          : station['dropoff_allowed'] as bool? ?? true;
      if (!allowed) return null;
      return _stationOrder(station);
    }
    return null;
  }

  int _stationOrder(dynamic station) {
    return station['sort_order'] as int? ?? 0;
  }

  String _priceRangeLabel(
    List<dynamic> pricedTrips, {
    required String currency,
  }) {
    if (pricedTrips.isEmpty) return 'Price pending';
    final prices = pricedTrips
        .map((trip) => (trip['ticket_price'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    if (prices.isEmpty) return 'Price pending';
    prices.sort();
    final min = prices.first;
    final max = prices.last;
    if (min == max) return '$currency ${_formatPrice(min)}';
    return '$currency ${_formatPrice(min)} - ${_formatPrice(max)}';
  }

  String _formatPrice(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(2);
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

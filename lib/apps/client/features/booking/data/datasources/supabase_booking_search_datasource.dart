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
      final pricingTrips = await _supabase
          .from('operation_trips')
          .select('''
            id, trip_date, departure_time, arrival_time, capacity, passenger_count, booked_seats,
            ticket_price, currency, status, route_id,
            vehicles(vehicle_type),
            trip_pricing(one_time_price, currency, is_active)
          ''')
          .eq('route_id', data['id'])
          .neq('status', 'cancelled')
          .limit(100);
      final today = DateTime.now().toIso8601String().split('T').first;
      final trips = pricingTrips.where((trip) {
        final status = trip['status']?.toString();
        final tripDate = trip['trip_date']?.toString();
        final isBookable = status == 'open_for_booking' || status == 'boarding';
        final isUpcoming = tripDate == null || tripDate.compareTo(today) >= 0;
        return isBookable && isUpcoming;
      }).toList();
      final priceSourceTrips = trips.isEmpty ? pricingTrips : trips;
      final availableSeats = trips.fold<int>(0, (sum, trip) {
        final capacity = trip['capacity'] as int? ?? 0;
        final used =
            trip['passenger_count'] as int? ??
            trip['booked_seats'] as int? ??
            0;
        final remaining = capacity - used;
        return sum + remaining.clamp(0, capacity).toInt();
      });
      final basePrice = _startingPriceLabel(priceSourceTrips);
      final priceRange = _priceRangeLabel(priceSourceTrips);
      final availableTrips = trips.map((trip) {
        final capacity = trip['capacity'] as int? ?? 0;
        final used =
            trip['passenger_count'] as int? ??
            trip['booked_seats'] as int? ??
            0;
        final remaining = capacity - used;
        final vehicle = trip['vehicles'] as Map<String, dynamic>? ?? {};

        return RouteTripOptionModel(
          id: trip['id']?.toString() ?? '',
          departureTime: trip['departure_time']?.toString() ?? 'Not set',
          arrivalTime: trip['arrival_time']?.toString() ?? 'Not set',
          availableSeats: remaining.clamp(0, capacity).toInt(),
          vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
          price: _startingPriceLabel([trip]),
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

    final routeIds = response
        .map((route) => route['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final today = DateTime.now().toIso8601String().split('T').first;
    final trips = routeIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
              .from('operation_trips')
              .select('''
          route_id, ticket_price, currency, status, trip_date,
          trip_pricing(one_time_price, currency, is_active)
        ''')
              .inFilter('route_id', routeIds)
              .neq('status', 'cancelled');

    return response.map((data) {
      final routeTrips = trips
          .where((trip) => trip['route_id'] == data['id'])
          .toList();
      final upcomingRouteTrips = routeTrips.where((trip) {
        final tripDate = trip['trip_date']?.toString();
        return tripDate == null || tripDate.compareTo(today) >= 0;
      }).toList();
      final basePrice = _startingPriceLabel(
        upcomingRouteTrips.isEmpty ? routeTrips : upcomingRouteTrips,
      );

      return PopularRouteListModel(
        id: data['id']?.toString() ?? '',
        routeName:
            data['name']?.toString() ??
            '${data['start_city']} — ${data['end_city']}',
        dailyTrips: upcomingRouteTrips.length,
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

  String _priceRangeLabel(List<dynamic> trips) {
    final candidates = <_PriceCandidate>[];
    for (final trip in trips) {
      candidates.addAll(_priceCandidatesFromTrip(trip));
    }
    if (candidates.isEmpty) return 'Price pending';
    candidates.sort((a, b) => a.amount.compareTo(b.amount));
    final currency = candidates.first.currency;
    final prices = candidates.map((candidate) => candidate.amount).toList();
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

  String _startingPriceLabel(List<dynamic> trips) {
    final candidates = <_PriceCandidate>[];
    for (final trip in trips) {
      candidates.addAll(_priceCandidatesFromTrip(trip));
    }
    if (candidates.isEmpty) return 'Price pending';
    candidates.sort((a, b) => a.amount.compareTo(b.amount));
    final cheapest = candidates.first;
    return '${cheapest.currency} ${_formatPrice(cheapest.amount)}';
  }

  List<_PriceCandidate> _priceCandidatesFromTrip(dynamic trip) {
    if (trip is! Map<String, dynamic>) return const [];

    final currency = trip['currency']?.toString() ?? 'ج.م';
    final candidates = <_PriceCandidate>[];
    final pricingRows = trip['trip_pricing'];
    if (pricingRows is List) {
      for (final row in pricingRows) {
        if (row is! Map<String, dynamic>) continue;
        final isActive = row['is_active'] as bool? ?? true;
        final amount = (row['one_time_price'] as num?)?.toDouble();
        if (!isActive || amount == null || amount <= 0) continue;
        candidates.add(
          _PriceCandidate(
            amount: amount,
            currency: row['currency']?.toString() ?? currency,
          ),
        );
      }
    }

    final ticketPrice = (trip['ticket_price'] as num?)?.toDouble();
    if (ticketPrice != null && ticketPrice > 0) {
      candidates.add(_PriceCandidate(amount: ticketPrice, currency: currency));
    }

    return candidates;
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
        .eq('status', 'open_for_booking')
        .limit(5);

    return response.map((data) {
      final vehicle = (data['vehicles'] as Map<String, dynamic>?) ?? {};
      final driver = (data['drivers'] as Map<String, dynamic>?) ?? {};
      final route = (data['operation_routes'] as Map<String, dynamic>?) ?? {};

      final capacity = vehicle['capacity'] as int? ?? 14;
      final passengerCount = data['passenger_count'] as int? ?? 0;
      final basePrice = _startingPriceLabel([data]);

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
        .select('name, latitude, longitude, operation_routes!inner(status)')
        .eq('operation_routes.status', 'active')
        .eq('pickup_allowed', true);

    final pinsByName = <String, MapPinOptionModel>{};
    for (final data in response) {
      final name = data['name']?.toString() ?? 'Station';
      pinsByName.putIfAbsent(
        name,
        () => MapPinOptionModel(
          label: name,
          subtitle: 'Pickup station',
          x: _toDouble(data['latitude']) ?? 30.0444,
          y: _toDouble(data['longitude']) ?? 31.2357,
        ),
      );
    }

    return pinsByName.values.toList();
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
        subtitle: 'Destination station',
        x: _toDouble(data['latitude']) ?? 30.0444,
        y: _toDouble(data['longitude']) ?? 31.2357,
      );
    }).toList();
  }
}

class _PriceCandidate {
  const _PriceCandidate({required this.amount, required this.currency});

  final double amount;
  final String currency;
}

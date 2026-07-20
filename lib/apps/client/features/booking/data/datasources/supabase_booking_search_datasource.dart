import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price_mapper.dart';
import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_search_query.dart';
import '../../domain/entities/search_options.dart';
import '../models/booking_option_model.dart';
import 'booking_search_datasource.dart';

class SupabaseBookingSearchDatasource implements BookingSearchDatasource {
  final SupabaseClient _supabase;

  static const int _maxTripsPerRoute = 100;

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
                'id, route_id, name, sort_order, latitude, longitude, pickup_allowed, dropoff_allowed',
              )
              .inFilter('route_id', routeIds)
              .order('sort_order');
    final stationsByRouteId = <String, List<dynamic>>{};
    for (final station in stationsResponse) {
      final routeId = station['route_id']?.toString();
      if (routeId == null || routeId.isEmpty) continue;
      stationsByRouteId.putIfAbsent(routeId, () => []).add(station);
    }

    final tripsByRouteId = await _tripsByRouteId(routeIds);

    final matchesRequestedRoute =
        query.routeId != null && query.routeId!.isNotEmpty;
    final List<_ScoredRoute> scored = [];

    for (var data in response) {
      final routeId = data['id']?.toString() ?? '';
      final stations = stationsByRouteId[routeId] ?? const <dynamic>[];
      final startCity = data['start_city']?.toString() ?? '';
      final endCity = data['end_city']?.toString() ?? '';
      final pricingTrips = tripsByRouteId[routeId] ?? const <dynamic>[];
      final trips = pricingTrips.where(_isBookableTrip).toList();
      if (trips.isEmpty) continue;
      final availableSeats = trips.fold<int>(0, (sum, trip) {
        return sum + _remainingSeats(trip);
      });
      final basePrice = _startingPriceLabel(trips);
      final priceRange = _priceRangeLabel(trips);
      final availableTrips = trips.map((trip) {
        final vehicle = trip['vehicles'] as Map<String, dynamic>? ?? {};
        final driver = trip['drivers'] as Map<String, dynamic>? ?? {};

        return RouteTripOptionModel(
          id: trip['id']?.toString() ?? '',
          tripDate: trip['trip_date']?.toString() ?? '',
          departureTime: trip['departure_time']?.toString() ?? 'Not set',
          arrivalTime: trip['arrival_time']?.toString() ?? 'Not set',
          availableSeats: _remainingSeats(trip),
          vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
          price: _startingPriceLabel([trip]),
          stopPricing: tripStopPairPricesFromJson(
            trip['trip_pricing'],
            stationIds: routeStationIdsFromJson(trip['trip_route_points']),
          ),
          vehicle: TripVehicleProfileModel.fromJson(
            vehicle: vehicle,
            driver: driver,
          ),
        );
      }).toList();
      final routePoints = _mapRoutePoints(
        stations,
        startCity: startCity,
        endCity: endCity,
      );

      final pickupMatch = _bestLocationMatch(
        query.pickup,
        routePoints,
        checkPickup: true,
        fallbackLabel: startCity,
      );
      final destMatch = _bestLocationMatch(
        query.destination,
        routePoints,
        checkPickup: false,
        fallbackLabel: endCity,
      );

      final bothMatched = pickupMatch.score > 0 && destMatch.score > 0;
      final orderValid = pickupMatch.order <= destMatch.order;

      final RouteMatchQuality quality;
      if (matchesRequestedRoute ||
          (pickupMatch.score >= 0.75 &&
              destMatch.score >= 0.75 &&
              orderValid)) {
        quality = RouteMatchQuality.exact;
      } else if (bothMatched && orderValid) {
        quality = RouteMatchQuality.partial;
      } else {
        quality = RouteMatchQuality.suggested;
      }

      final relevance =
          (matchesRequestedRoute ? 100.0 : 0.0) +
          destMatch.score * 1.2 +
          pickupMatch.score +
          (bothMatched && orderValid ? 0.5 : 0.0);

      final displayPickup = pickupMatch.label.isNotEmpty
          ? pickupMatch.label
          : (query.pickup.isEmpty ? startCity : query.pickup);
      final displayDest = destMatch.label.isNotEmpty
          ? destMatch.label
          : (query.destination.isEmpty ? endCity : query.destination);

      scored.add(
        _ScoredRoute(
          relevance: relevance,
          hasTrips: trips.isNotEmpty,
          availableSeats: availableSeats,
          model: RouteOptionModel(
            id: routeId,
            routeName: data['name']?.toString().trim().isNotEmpty == true
                ? data['name'].toString()
                : '$startCity - $endCity',
            pickup: displayPickup,
            destination: displayDest,
            distance: data['distance']?.toString() ?? 'Not set',
            duration: data['duration']?.toString() ?? 'N/A',
            availableSeats: availableSeats,
            startingPrice: basePrice,
            priceRange: priceRange,
            availableTrips: availableTrips,
            points: routePoints,
            matchQuality: quality,
          ),
        ),
      );
    }

    scored.sort((a, b) {
      final byRelevance = b.relevance.compareTo(a.relevance);
      if (byRelevance != 0) return byRelevance;
      if (a.hasTrips != b.hasTrips) return a.hasTrips ? -1 : 1;
      return b.availableSeats.compareTo(a.availableSeats);
    });

    return scored.take(8).map((entry) => entry.model).toList();
  }

  /// Loads the bookable trips for every route in one round-trip, keyed by route.
  /// Querying per route made Route Details wait on one sequential request per
  /// active route before it could leave its loading state.
  Future<Map<String, List<dynamic>>> _tripsByRouteId(
    List<String> routeIds,
  ) async {
    if (routeIds.isEmpty) return const {};
    final response = await _supabase
        .from('operation_trips')
        .select('''
          id, trip_date, departure_time, arrival_time, capacity, passenger_count, booked_seats,
          ticket_price, currency, status, route_id,
          vehicles(vehicle_type, brand, model, plate_number, color,
                   manufacture_year, capacity, seat_layout_type, features,
                   image_url, rating, rating_count),
          drivers(full_name, profile_image_url, rating, rating_count),
          trip_pricing(from_point_id, to_point_id, one_time_price, five_days_price, ten_days_price, monthly_price, three_months_price, currency, is_active),
          trip_route_points(id, route_point_id),
          trip_seats(state)
        ''')
        .inFilter('route_id', routeIds);

    final grouped = <String, List<dynamic>>{};
    for (final trip in response) {
      final routeId = trip['route_id']?.toString();
      if (routeId == null || routeId.isEmpty) continue;
      final trips = grouped.putIfAbsent(routeId, () => []);
      if (trips.length < _maxTripsPerRoute) trips.add(trip);
    }
    return grouped;
  }

  /// Scores how well a route serves [query] and returns the closest stop.
  _LocationMatch _bestLocationMatch(
    String query,
    List<RoutePointModel> points, {
    required bool checkPickup,
    required String fallbackLabel,
  }) {
    final candidates = points
        .where((p) => checkPickup ? p.pickupAllowed : p.dropoffAllowed)
        .toList();
    final fallbackOrder = candidates.isEmpty
        ? 0
        : (checkPickup ? candidates.first.order : candidates.last.order);

    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty || candidates.isEmpty) {
      return _LocationMatch(
        label: fallbackLabel,
        order: fallbackOrder,
        score: 0,
      );
    }

    RoutePointModel? best;
    var bestScore = 0.0;
    for (final candidate in candidates) {
      final score = _textSimilarity(normalized, candidate.name.toLowerCase());
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    if (best == null || bestScore == 0) {
      return _LocationMatch(
        label: fallbackLabel,
        order: fallbackOrder,
        score: 0,
      );
    }
    return _LocationMatch(
      label: best.name,
      order: best.order,
      score: bestScore,
    );
  }

  double _textSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (a.contains(b) || b.contains(a)) return 0.8;
    final aTokens = _tokens(a);
    final bTokens = _tokens(b);
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    final shared = aTokens.intersection(bTokens).length;
    if (shared == 0) return 0;
    return 0.6 * (shared / aTokens.length);
  }

  Set<String> _tokens(String value) {
    const stopwords = {'of', 'the', 'and', 'egypt'};
    return value
        .split(RegExp(r'[\s,.\-]+'))
        .where((t) => t.length > 1 && !stopwords.contains(t))
        .toSet();
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
    final trips = routeIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
              .from('operation_trips')
              .select('''
          route_id, ticket_price, currency, status, trip_date,
          capacity, passenger_count, booked_seats,
          trip_pricing(one_time_price, currency, is_active),
          trip_seats(state)
        ''')
              .inFilter('route_id', routeIds)
              .eq('status', 'open_for_booking');

    return response
        .map((data) {
          final routeTrips = trips
              .where((trip) => trip['route_id'] == data['id'])
              .toList();
          final bookableRouteTrips = routeTrips.where(_isBookableTrip).toList();
          final basePrice = _startingPriceLabel(bookableRouteTrips);

          return PopularRouteListModel(
            id: data['id']?.toString() ?? '',
            routeName:
                data['name']?.toString() ??
                '${data['start_city']} — ${data['end_city']}',
            dailyTrips: bookableRouteTrips.length,
            averageDuration: data['duration']?.toString() ?? 'N/A',
            startingPrice: basePrice,
            pickup: data['start_city']?.toString() ?? '',
            destination: data['end_city']?.toString() ?? '',
            distance: data['distance']?.toString() ?? 'Not set',
          );
        })
        .where((route) => route.dailyTrips > 0)
        .toList();
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
                id: station['id']?.toString() ?? '',
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

    final currency = trip['currency']?.toString() ?? 'EGP';
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

  @override
  Future<TripSearchOptions> getSearchOptions() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final results = await Future.wait([
      _supabase
          .from('route_stations')
          .select('name, operation_routes!inner(status)')
          .eq('operation_routes.status', 'active')
          .eq('pickup_allowed', true),
      _supabase
          .from('route_stations')
          .select('name, operation_routes!inner(status)')
          .eq('operation_routes.status', 'active')
          .eq('dropoff_allowed', true),
      _supabase
          .from('operation_trips')
          .select('''
            departure_time, status, trip_date, capacity, passenger_count,
            booked_seats, ticket_price, currency,
            trip_pricing(one_time_price, currency, is_active),
            trip_seats(state)
          ''')
          .eq('status', 'open_for_booking')
          .gte('trip_date', today),
    ]);

    final pickups =
        results[0]
            .map((s) => s['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final destinations =
        results[1]
            .map((s) => s['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final times =
        results[2]
            .where(_isBookableTrip)
            .map(
              (t) =>
                  _formatDepartureTime(t['departure_time']?.toString() ?? ''),
            )
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return TripSearchOptions(
      pickupPoints: pickups,
      destinations: destinations,
      departureTimes: times,
    );
  }

  String _formatDepartureTime(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int _remainingSeats(dynamic trip) {
    if (trip is! Map<String, dynamic>) return 0;
    final seats = trip['trip_seats'];
    if (seats is List) {
      return seats.where((seat) {
        return seat is Map && seat['state']?.toString() == 'available';
      }).length;
    }
    final capacity = trip['capacity'] as int? ?? 0;
    final used =
        trip['passenger_count'] as int? ?? trip['booked_seats'] as int? ?? 0;
    return (capacity - used).clamp(0, capacity).toInt();
  }

  bool _isBookableTrip(dynamic trip) {
    if (trip is! Map<String, dynamic>) return false;
    final status = trip['status']?.toString();
    final tripDate = trip['trip_date']?.toString();
    final today = DateTime.now().toIso8601String().split('T').first;
    final isUpcoming = tripDate == null || tripDate.compareTo(today) >= 0;

    return status == 'open_for_booking' &&
        isUpcoming &&
        _remainingSeats(trip) > 0 &&
        _priceCandidatesFromTrip(trip).isNotEmpty;
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
      final name = data['name']?.toString().trim() ?? '';
      final latitude = _toDouble(data['latitude']);
      final longitude = _toDouble(data['longitude']);
      if (name.isEmpty || !_isValidCoordinate(latitude, longitude)) continue;
      pinsByName.putIfAbsent(
        name,
        () => MapPinOptionModel(
          label: name,
          subtitle: 'Pickup station',
          x: latitude!,
          y: longitude!,
        ),
      );
    }

    final pins = pinsByName.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return pins;
  }

  @override
  Future<List<MapPinOptionModel>> getDestinationMapPins() async {
    final response = await _supabase
        .from('route_stations')
        .select('name, latitude, longitude, operation_routes!inner(status)')
        .eq('operation_routes.status', 'active')
        .eq('dropoff_allowed', true);

    final pinsByName = <String, MapPinOptionModel>{};
    for (final data in response) {
      final name = data['name']?.toString().trim() ?? '';
      final latitude = _toDouble(data['latitude']);
      final longitude = _toDouble(data['longitude']);
      if (name.isEmpty || !_isValidCoordinate(latitude, longitude)) continue;
      pinsByName.putIfAbsent(
        name,
        () => MapPinOptionModel(
          label: name,
          subtitle: 'Destination station',
          x: latitude!,
          y: longitude!,
        ),
      );
    }

    final pins = pinsByName.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return pins;
  }

  bool _isValidCoordinate(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        (latitude != 0 || longitude != 0) &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}

class _PriceCandidate {
  const _PriceCandidate({required this.amount, required this.currency});

  final double amount;
  final String currency;
}

/// A route paired with its relevance score for ranking search results.
class _ScoredRoute {
  const _ScoredRoute({
    required this.model,
    required this.relevance,
    required this.hasTrips,
    required this.availableSeats,
  });

  final RouteOptionModel model;
  final double relevance;
  final bool hasTrips;
  final int availableSeats;
}

/// The closest stop on a route to a searched location, with a 0–1 score.
class _LocationMatch {
  const _LocationMatch({
    required this.label,
    required this.order,
    required this.score,
  });

  final String label;
  final int order;
  final double score;
}

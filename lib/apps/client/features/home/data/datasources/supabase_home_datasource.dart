import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_data_model.dart';
import 'home_datasource.dart';

class SupabaseHomeDatasource implements HomeDatasource {
  final SupabaseClient _supabase;

  const SupabaseHomeDatasource(this._supabase);

  @override
  Future<HomeDataModel> getHomeData() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final routesFuture = _supabase
        .from('operation_routes')
        .select('id, name, start_city, end_city, duration, status')
        .eq('status', 'active');

    final tripsFuture = _supabase
        .from('operation_trips')
        .select('*, route:operation_routes(start_city, end_city)')
        .gte('trip_date', today)
        .inFilter('status', ['open_for_booking', 'boarding'])
        .order('trip_date')
        .order('departure_time')
        .limit(50);

    final packagesFuture = _supabase
        .from('packages')
        .select()
        .eq('status', 'active');

    final user = _supabase.auth.currentUser;
    Future<List<Map<String, dynamic>>>? currentTripFuture;
    if (user != null) {
      currentTripFuture = _supabase
          .from('operation_bookings')
          .select()
          .eq('client_id', user.id)
          .inFilter('status', ['newRequest', 'approved', 'active'])
          .limit(1);
    }

    final responses = await Future.wait([
      routesFuture,
      tripsFuture,
      packagesFuture,
      if (currentTripFuture != null) currentTripFuture else Future.value([]),
    ]);

    final routesData = responses[0];
    final tripsData = responses[1];
    final packagesData = responses[2];
    final currentTripData = responses[3];

    final routeIds = routesData
        .map((route) => route['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final pricingTripsData = routeIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
              .from('operation_trips')
              .select('''
                route_id, ticket_price, currency, status, trip_date,
                trip_pricing(one_time_price, currency, is_active)
              ''')
              .inFilter('route_id', routeIds)
              .neq('status', 'cancelled')
              .limit(500);

    final tripsByRoute = <String, List<dynamic>>{};
    for (final trip in tripsData) {
      final routeId = trip['route_id']?.toString();
      if (routeId == null || routeId.isEmpty) continue;
      tripsByRoute.putIfAbsent(routeId, () => []).add(trip);
    }
    final pricingTripsByRoute = <String, List<dynamic>>{};
    for (final trip in pricingTripsData) {
      final routeId = trip['route_id']?.toString();
      if (routeId == null || routeId.isEmpty) continue;
      pricingTripsByRoute.putIfAbsent(routeId, () => []).add(trip);
    }

    final sortedRoutesData = [...routesData]
      ..sort((a, b) {
        final aTrips = tripsByRoute[a['id']?.toString()]?.length ?? 0;
        final bTrips = tripsByRoute[b['id']?.toString()]?.length ?? 0;
        return bTrips.compareTo(aTrips);
      });

    final popularRoutesData = sortedRoutesData.take(8).toList();
    final nearbyTripsData = tripsData.take(3).toList();

    final popularRoutes = popularRoutesData.map((e) {
      final routeId = e['id']?.toString() ?? '';
      final routeTrips = tripsByRoute[routeId] ?? const <dynamic>[];
      final pricingTrips = pricingTripsByRoute[routeId] ?? routeTrips;
      final startingPrice = _startingPriceLabel(pricingTrips);
      final startCity = e['start_city'] as String? ?? '';
      final endCity = e['end_city'] as String? ?? '';

      return PopularRouteModel(
        id: routeId,
        routeName: e['name']?.toString().trim().isNotEmpty == true
            ? e['name'].toString()
            : '$startCity to $endCity',
        pickup: e['start_city'] as String? ?? '',
        destination: e['end_city'] as String? ?? '',
        duration: e['duration']?.toString() ?? '',
        startingPrice: startingPrice,
        tripsAvailable: routeTrips.length,
      );
    }).toList();

    final nearbyTrips = nearbyTripsData.map((e) {
      final route = e['route'] as Map<String, dynamic>? ?? {};
      final capacity = e['capacity'] as int? ?? 0;
      final passengerCount = e['passenger_count'] as int? ?? 0;
      final departureTime =
          e['departure_time']?.toString() ?? e['trip_date']?.toString() ?? '';

      return NearbyTripModel(
        pickup: route['start_city'] as String? ?? '',
        destination: route['end_city'] as String? ?? '',
        departureTime: departureTime,
        seatsLeft: capacity - passengerCount,
        isLive: e['status'] == 'in_progress' || e['status'] == 'boarding',
      );
    }).toList();

    final packagePlans = packagesData
        .map(
          (e) => PackagePlanModel(
            title: e['title'] as String? ?? '',
            subtitle: e['subtitle'] as String? ?? '',
            price: e['price']?.toString() ?? '',
            badge: e['badge'] as String? ?? '',
            iconKey: e['icon_key'] as String? ?? 'dateRange',
          ),
        )
        .toList();

    HomeCurrentTripModel? currentTrip;
    if (currentTripData.isNotEmpty) {
      final trip = currentTripData.first;
      currentTrip = HomeCurrentTripModel(
        id: trip['id']?.toString() ?? '',
        pickup: trip['route']?.toString().split(' ').first ?? '',
        destination: trip['route']?.toString().split(' ').last ?? '',
        schedule: '${trip['trip_date']} · ${trip['trip_time']}',
        statusLabel: trip['assigned_trip']?.toString() ?? 'Processing',
        driverLine: trip['status'] == 'active'
            ? 'Driver assigned'
            : 'Waiting for assignment',
      );
    }

    final pickupSet = <String>{};
    final destinationSet = <String>{};
    for (var r in routesData) {
      if (r['start_city'] != null && r['start_city'].toString().isNotEmpty) {
        pickupSet.add(r['start_city'].toString());
      }
      if (r['end_city'] != null && r['end_city'].toString().isNotEmpty) {
        destinationSet.add(r['end_city'].toString());
      }
    }

    final timeSet = <String>{};
    for (var t in tripsData) {
      if (t['departure_time'] != null &&
          t['departure_time'].toString().isNotEmpty) {
        timeSet.add(t['departure_time'].toString());
      }
    }

    final userName =
        user?.userMetadata?['full_name']?.toString() ??
        user?.userMetadata?['name']?.toString() ??
        'User';

    return HomeDataModel(
      popularRoutes: popularRoutes,
      nearbyTrips: nearbyTrips,
      packagePlans: packagePlans,
      pickupSuggestions: pickupSet.toList(),
      destinationSuggestions: destinationSet.toList(),
      timeSuggestions: timeSet.toList(),
      userName: userName,
      currentTrip: currentTrip,
    );
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

  String _formatPrice(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(2);
  }
}

class _PriceCandidate {
  const _PriceCandidate({required this.amount, required this.currency});

  final double amount;
  final String currency;
}

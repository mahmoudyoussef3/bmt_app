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
        .inFilter('status', ['scheduled', 'openForBooking'])
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

    final tripsByRoute = <String, List<dynamic>>{};
    for (final trip in tripsData) {
      final routeId = trip['route_id']?.toString();
      if (routeId == null || routeId.isEmpty) continue;
      tripsByRoute.putIfAbsent(routeId, () => []).add(trip);
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
      final firstPricedTrip = pricedTrips.isNotEmpty ? pricedTrips.first : null;
      final startingPrice = firstPricedTrip == null
          ? 'Price pending'
          : '${firstPricedTrip['currency'] ?? 'EGP'} ${firstPricedTrip['ticket_price']}';
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
}

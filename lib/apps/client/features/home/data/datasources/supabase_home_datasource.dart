import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_data_model.dart';
import 'home_datasource.dart';

class SupabaseHomeDatasource implements HomeDatasource {
  final SupabaseClient _supabase;

  const SupabaseHomeDatasource(this._supabase);

  @override
  Future<HomeDataModel> getHomeData() async {
    final routesFuture = _supabase
        .from('operation_routes')
        .select()
        .eq('status', 'active');

    final tripsFuture = _supabase
        .from('operation_trips')
        .select('*, route:operation_routes(start_city, end_city)')
        .eq('status', 'scheduled')
        .order('trip_date')
        .order('departure_time')
        .limit(10);

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

    final routesData = responses[0] as List<dynamic>;
    final tripsData = responses[1] as List<dynamic>;
    final packagesData = responses[2] as List<dynamic>;
    final currentTripData = responses[3] as List<dynamic>;

    final popularRoutesData = routesData.take(4).toList();
    final nearbyTripsData = tripsData.take(3).toList();

    final popularRoutes = popularRoutesData.map((e) => PopularRouteModel(
          pickup: e['start_city'] as String? ?? '',
          destination: e['end_city'] as String? ?? '',
          duration: e['duration']?.toString() ?? '',
          startingPrice: '', 
        )).toList();

    final nearbyTrips = nearbyTripsData.map((e) {
      final route = e['route'] as Map<String, dynamic>? ?? {};
      final capacity = e['capacity'] as int? ?? 0;
      final passengerCount = e['passenger_count'] as int? ?? 0;
      final departureTime = e['departure_time']?.toString() ?? e['trip_date']?.toString() ?? '';
      
      return NearbyTripModel(
          pickup: route['start_city'] as String? ?? '', 
          destination: route['end_city'] as String? ?? '', 
          departureTime: departureTime,
          seatsLeft: capacity - passengerCount,
          isLive: e['status'] == 'in_progress' || e['status'] == 'boarding',
        );
    }).toList();

    final packagePlans = packagesData.map((e) => PackagePlanModel(
          title: e['title'] as String? ?? '',
          subtitle: e['subtitle'] as String? ?? '',
          price: e['price']?.toString() ?? '',
          badge: e['badge'] as String? ?? '',
          iconKey: e['icon_key'] as String? ?? 'dateRange',
        )).toList();

    HomeCurrentTripModel? currentTrip;
    if (currentTripData.isNotEmpty) {
      final trip = currentTripData.first;
      currentTrip = HomeCurrentTripModel(
        id: trip['id']?.toString() ?? '',
        pickup: trip['route']?.toString().split(' ').first ?? '',
        destination: trip['route']?.toString().split(' ').last ?? '',
        schedule: '${trip['trip_date']} · ${trip['trip_time']}',
        statusLabel: trip['assigned_trip']?.toString() ?? 'Processing',
        driverLine: trip['status'] == 'active' ? 'Driver assigned' : 'Waiting for assignment',
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
      if (t['departure_time'] != null && t['departure_time'].toString().isNotEmpty) {
        timeSet.add(t['departure_time'].toString());
      }
    }

    final userName = user?.userMetadata?['full_name']?.toString() 
        ?? user?.userMetadata?['name']?.toString() 
        ?? 'User';

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

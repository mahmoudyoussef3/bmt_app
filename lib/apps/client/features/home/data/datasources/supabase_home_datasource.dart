import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_data_model.dart';
import 'home_datasource.dart';

class SupabaseHomeDatasource implements HomeDatasource {
  final SupabaseClient _supabase;

  const SupabaseHomeDatasource(this._supabase);

  @override
  Future<HomeDataModel> getHomeData() async {
    final popularRoutesFuture = _supabase
        .from('operation_routes')
        .select()
        .eq('status', 'active')
        .limit(4);

    final nearbyTripsFuture = _supabase
        .from('operation_trips')
        .select()
        .eq('status', 'scheduled')
        .limit(3);

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
      popularRoutesFuture,
      nearbyTripsFuture,
      packagesFuture,
      if (currentTripFuture != null) currentTripFuture else Future.value([]),
    ]);

    final popularRoutesData = responses[0];
    final nearbyTripsData = responses[1];
    final packagesData = responses[2];
    final currentTripData = responses[3];

    final popularRoutes = popularRoutesData.map((e) => PopularRouteModel(
          pickup: e['start_point'] as String? ?? 'Unknown',
          destination: e['end_point'] as String? ?? 'Unknown',
          duration: e['estimated_time']?.toString() ?? '60 mins',
          startingPrice: 'Starts from EGP 50', // We will join trip_pricing or set it realistically
        )).toList();

    final nearbyTrips = nearbyTripsData.map((e) => NearbyTripModel(
          pickup: 'Terminal', // Or fallback to real station
          destination: 'Destination', 
          departureTime: e['trip_date']?.toString() ?? '',
          seatsLeft: 14 - ((e['passenger_count'] as int?) ?? 0),
          isLive: e['status'] == 'active',
        )).toList();

    final packagePlans = packagesData.map((e) => PackagePlanModel(
          title: e['title'] as String? ?? '',
          subtitle: e['subtitle'] as String? ?? '',
          price: 'EGP ${e['price']}',
          badge: e['badge'] as String? ?? '',
          iconKey: e['icon_key'] as String? ?? 'dateRange',
        )).toList();

    HomeCurrentTripModel? currentTrip;
    if (currentTripData.isNotEmpty) {
      final trip = currentTripData.first;
      currentTrip = HomeCurrentTripModel(
        pickup: trip['route']?.toString().split(' ').first ?? 'Pickup',
        destination: trip['route']?.toString().split(' ').last ?? 'Destination',
        schedule: '${trip['trip_date']} · Departs ${trip['trip_time']}',
        statusLabel: trip['assigned_trip']?.toString() ?? 'Processing',
        driverLine: trip['status'] == 'active' ? 'Driver assigned' : 'Waiting for assignment',
      );
    }

    // Suggestions can be derived from routes in a robust implementation
    final pickupSuggestions = ['Banha Center', 'Banha Station', 'Smart Village Gate'];
    final destinationSuggestions = ['Smart Village', 'Nasr City', 'Mohandessin'];
    final timeSuggestions = ['7:30 AM', '8:00 AM', '8:30 AM', '9:00 AM'];

    return HomeDataModel(
      popularRoutes: popularRoutes,
      nearbyTrips: nearbyTrips,
      packagePlans: packagePlans,
      pickupSuggestions: pickupSuggestions,
      destinationSuggestions: destinationSuggestions,
      timeSuggestions: timeSuggestions,
      currentTrip: currentTrip,
    );
  }
}

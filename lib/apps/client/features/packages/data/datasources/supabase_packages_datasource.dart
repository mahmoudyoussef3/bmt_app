import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_plan_model.dart';
import 'packages_datasource.dart';

class SupabasePackagesDatasource implements PackagesDatasource {
  final SupabaseClient _supabase;

  const SupabasePackagesDatasource(this._supabase);

  @override
  Future<PackageSelectionDataModel> getSelectionData() async {
    final packagesFuture = _supabase.from('packages').select().eq('status', 'active');
    final vehicleTiersFuture = _supabase.from('package_vehicle_tiers').select().eq('status', 'active');
    final routesFuture = _supabase.from('operation_routes').select('start_point, end_point').eq('status', 'active');

    final responses = await Future.wait([
      packagesFuture,
      vehicleTiersFuture,
      routesFuture,
    ]);

    final packagesData = responses[0] as List<dynamic>;
    final vehicleTiersData = responses[1] as List<dynamic>;
    final routesData = responses[2] as List<dynamic>;

    final packages = packagesData.map((e) => PackagePlanModel(
          name: e['title']?.toString() ?? '',
          durationLabel: e['subtitle']?.toString() ?? '',
          days: e['days'] as int? ?? 30,
          tripsCount: e['trips_count'] as int? ?? 44,
          discountPercent: e['discount_percent'] as int? ?? 0,
          startingPrice: (e['price'] as num?)?.toInt() ?? 0,
          savingsAmount: (e['savings_amount'] as num?)?.toInt() ?? 0,
          description: e['description']?.toString() ?? '',
        )).toList();

    final vehicles = vehicleTiersData.map((e) => PackageVehicleTypeModel(
          name: e['name']?.toString() ?? '',
          iconKey: e['icon_key']?.toString() ?? 'bus',
          extraFee: (e['extra_fee'] as num?)?.toInt() ?? 0,
          description: e['description']?.toString() ?? '',
        )).toList();

    final pickups = routesData.map((e) => e['start_point']?.toString() ?? '').toSet().toList();
    final destinations = routesData.map((e) => e['end_point']?.toString() ?? '').toSet().toList();
    final routeNames = routesData.map((e) => '${e['start_point']} - ${e['end_point']}').toSet().toList();

    // Ideally fetched from active seat mapping for a chosen trip, hardcoded stub for now
    final occupiedSeats = {3, 7, 12, 16};

    return PackageSelectionDataModel(
      packages: packages,
      routes: routeNames.isNotEmpty ? routeNames : ['Banha - Cairo Express'],
      pickupPoints: pickups.isNotEmpty ? pickups : ['Banha Station'],
      destinations: destinations.isNotEmpty ? destinations : ['Smart Village'],
      vehicles: vehicles,
      occupiedSeats: occupiedSeats,
    );
  }
}

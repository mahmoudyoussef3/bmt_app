import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/subscription_request.dart';
import '../models/package_plan_model.dart';
import 'packages_datasource.dart';

class SupabasePackagesDatasource implements PackagesDatasource {
  final SupabaseClient _supabase;

  const SupabasePackagesDatasource(this._supabase);

  @override
  Future<String> createSubscription(SubscriptionRequest request) async {
    // This is no longer directly creating a subscription for SaaS Booking Flow.
    // The subscription is created by the RPC `approve_payment` when the booking is approved.
    // So this is technically deprecated or should just throw unimplmented if used in the new flow.
    throw UnimplementedError('createSubscription is deprecated. Use confirm_seat_booking_v2 instead.');
  }

  @override
  Future<PackageSelectionDataModel> getSelectionData() async {
    final packagesFuture = _supabase
        .from('transport_packages')
        .select()
        .eq('active', true)
        .order('display_order', ascending: true);
        
    final vehicleTiersFuture = _supabase
        .from('package_vehicle_tiers')
        .select()
        .eq('status', 'active');
        
    final routesFuture = _supabase
        .from('operation_routes')
        .select('name, start_city, end_city')
        .eq('status', 'active');

    final responses = await Future.wait([
      packagesFuture,
      vehicleTiersFuture,
      routesFuture,
    ]);

    final packagesData = responses[0] as List<dynamic>;
    final vehicleTiersData = responses[1] as List<dynamic>;
    final routesData = responses[2] as List<dynamic>;

    final packages = packagesData
        .map((e) => PackagePlanModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final vehicles = vehicleTiersData
        .map(
          (e) => PackageVehicleTypeModel(
            name: e['name']?.toString() ?? '',
            iconKey: e['icon_key']?.toString() ?? 'bus',
            extraFee: (e['extra_fee'] as num?)?.toInt() ?? 0,
            description: e['description']?.toString() ?? '',
          ),
        )
        .toList();

    final pickups = _uniqueNonEmpty(
      routesData.map((e) => e['start_city']?.toString() ?? ''),
    );
    final destinations = _uniqueNonEmpty(
      routesData.map((e) => e['end_city']?.toString() ?? ''),
    );
    final routeNames = _uniqueNonEmpty(
      routesData.map((e) {
        final name = e['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) return name;
        final start = e['start_city']?.toString().trim() ?? '';
        final end = e['end_city']?.toString().trim() ?? '';
        if (start.isEmpty || end.isEmpty) return '';
        return '$start - $end';
      }),
    );

    return PackageSelectionDataModel(
      packages: packages,
      routes: routeNames,
      pickupPoints: pickups,
      destinations: destinations,
      vehicles: vehicles,
      occupiedSeats: const {},
    );
  }

  List<String> _uniqueNonEmpty(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      result.add(normalized);
    }
    return result;
  }
}

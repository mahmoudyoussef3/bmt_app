import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/subscription_request.dart';
import '../models/package_plan_model.dart';
import 'packages_datasource.dart';

class SupabasePackagesDatasource implements PackagesDatasource {
  final SupabaseClient _supabase;

  const SupabasePackagesDatasource(this._supabase);

  @override
  Future<String> createSubscription(SubscriptionRequest request) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to subscribe.');
    }

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final now = DateTime.now();
    final durationDays = request.days > 0 ? request.days - 1 : 0;
    final end = now.add(Duration(days: durationDays));

    final payload = {
      'client_id': user.id,
      'package_id': request.packageId,
      'customer_name': meta['full_name']?.toString() ?? '',
      'customer_phone': meta['phone']?.toString() ?? '',
      'package_name': request.packageName,
      'route_name': request.routeName,
      'start_date': now.toIso8601String(),
      'end_date': end.toIso8601String(),
      'status': 'pending_payment',
      'total_price': request.totalPrice,
      'paid_amount': 0,
      'remaining_amount': request.totalPrice,
      'trips_count': request.tripsCount,
      'trips_used': 0,
      'payment_review_status': 'pending',
    };

    final row = await _supabase
        .from('subscriptions')
        .insert(payload)
        .select('id')
        .single();

    return row['id'].toString();
  }

  @override
  Future<PackageSelectionDataModel> getSelectionData() async {
    final packagesFuture = _supabase
        .from('packages')
        .select()
        .eq('status', 'active');
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
        .map(
          (e) => PackagePlanModel(
            id: e['id']?.toString() ?? '',
            name: e['title']?.toString() ?? '',
            durationLabel: e['subtitle']?.toString() ?? '',
            days: e['days'] as int? ?? 30,
            tripsCount: e['trips_count'] as int? ?? 44,
            discountPercent: e['discount_percent'] as int? ?? 0,
            startingPrice: (e['price'] as num?)?.toInt() ?? 0,
            savingsAmount: (e['savings_amount'] as num?)?.toInt() ?? 0,
            description: e['description']?.toString() ?? '',
          ),
        )
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

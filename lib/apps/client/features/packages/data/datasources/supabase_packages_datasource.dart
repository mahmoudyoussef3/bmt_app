import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/package_plan_model.dart';
import 'packages_datasource.dart';

class SupabasePackagesDatasource implements PackagesDatasource {
  const SupabasePackagesDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const _columns =
      '*, office:public_offices(id, name, logo_url, rating, '
      'ratings_count, description, service_areas)';

  @override
  Future<List<PackagePlanModel>> getPackages({String? officeId}) async {
    var query = _supabase
        .from('transport_packages')
        .select(_columns)
        .eq('active', true)
        // Catalog packages only. A package with `trip_id` set belongs to one
        // trip's fare menu and is never browsable on its own — see
        // `20260820100000_trip_scoped_packages.sql`.
        .isFilter('trip_id', null);

    if (officeId != null && officeId.isNotEmpty) {
      query = query.eq('office_id', officeId);
    }

    final rows = await query.order('display_order', ascending: true);

    return rows
        .map((row) => PackagePlanModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<List<PackagePlanModel>> getTripPackages({
    required String officeId,
    required Set<String> packageIds,
  }) async {
    if (officeId.isEmpty) return const [];

    // The trip's own menu, plus the walk-up single-ride package. The walk-up
    // one is deliberately NOT in `trip_package_prices` — its fare is the
    // trip's `one_time_price` — so it has to be asked for by shape rather
    // than by id, or a rider could not buy a single ride at all.
    const walkUp = 'and(trip_id.is.null,duration_days.lte.1,ride_count.eq.1)';
    final ids = packageIds.where((id) => id.trim().isNotEmpty).toList();
    final filter = ids.isEmpty ? walkUp : 'id.in.(${ids.join(',')}),$walkUp';

    final rows = await _supabase
        .from('transport_packages')
        .select(_columns)
        .eq('active', true)
        .eq('office_id', officeId)
        .or(filter)
        .order('display_order', ascending: true);

    return rows
        .map((row) => PackagePlanModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> getMySubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Future.value(null);

    return _supabase
        .from('subscriptions')
        .select(
          'id, package_name, route_name, status, start_date, end_date, '
          'trips_count, trips_used',
        )
        .eq('client_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/package_plan_model.dart';
import 'packages_datasource.dart';

class SupabasePackagesDatasource implements PackagesDatasource {
  const SupabasePackagesDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<PackagePlanModel>> getPackages({String? officeId}) async {
    // Packages are per-office offers competing in one catalogue, so each row
    // carries its seller's public identity — name, logo and rating — embedded
    // from the anon-safe `public_offices` view. That view already excludes
    // paused/unlisted offices, so a package whose seller is not for sale comes
    // back with a null `office`; the repository drops those.
    var query = _supabase
        .from('transport_packages')
        .select(
          '*, office:public_offices(id, name, logo_url, rating, '
          'ratings_count, description, service_areas)',
        )
        .eq('active', true);

    // The office profile reuses this to list one seller's packages.
    if (officeId != null && officeId.isNotEmpty) {
      query = query.eq('office_id', officeId);
    }

    final rows = await query.order('display_order', ascending: true);

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

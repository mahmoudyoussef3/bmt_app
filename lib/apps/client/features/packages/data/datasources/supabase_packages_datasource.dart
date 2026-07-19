import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/package_plan_model.dart';
import 'packages_datasource.dart';

class SupabasePackagesDatasource implements PackagesDatasource {
  const SupabasePackagesDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<PackagePlanModel>> getPackages() async {
    final rows = await _supabase
        .from('transport_packages')
        .select()
        .eq('active', true)
        .order('display_order', ascending: true);

    return rows
        .map((row) => PackagePlanModel.fromJson(row))
        .toList(growable: false);
  }
}

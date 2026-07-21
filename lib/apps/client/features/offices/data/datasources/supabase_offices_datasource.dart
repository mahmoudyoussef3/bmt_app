import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/office_route_model.dart';
import '../models/office_summary_model.dart';
import 'offices_datasource.dart';

class SupabaseOfficesDatasource implements OfficesDatasource {
  const SupabaseOfficesDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// `public_offices` already excludes paused/suspended offices and every
  /// private column, so this is a straight read of the marketplace surface.
  /// Best-rated first; unrated newcomers keep a stable alphabetical order.
  @override
  Future<List<OfficeSummaryModel>> fetchOffices() async {
    final rows = await _supabase
        .from('public_offices')
        .select()
        .order('rating', ascending: false)
        .order('name', ascending: true);

    return rows
        .map((row) => OfficeSummaryModel.fromJson(row))
        .toList(growable: false);
  }

  /// Active routes of one office. The marketplace RLS policy on
  /// `operation_routes` already constrains anon/client reads to active routes
  /// of active offices; the filters here mirror it rather than relax it.
  @override
  Future<List<OfficeRouteModel>> fetchOfficeRoutes(String officeId) async {
    final rows = await _supabase
        .from('operation_routes')
        .select('id, name, start_city, end_city')
        .eq('office_id', officeId)
        .eq('status', 'active')
        .order('name', ascending: true);

    return rows
        .map((row) => OfficeRouteModel.fromJson(row))
        .toList(growable: false);
  }
}

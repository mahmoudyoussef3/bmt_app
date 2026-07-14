import 'package:supabase_flutter/supabase_flutter.dart';

/// The reads behind the profile hub, kept apart from the datasource so the
/// datasource reads as "what the hub needs" rather than as SQL.
class ProfileQueries {
  const ProfileQueries(this._supabase);

  final SupabaseClient _supabase;

  /// Seats the rider still holds on a departure that has not run.
  static const liveStatuses = <String>['reserved', 'confirmed', 'boarded'];

  /// Trips the rider actually travelled.
  static const completedStatuses = <String>['completed'];

  Future<Map<String, dynamic>?> clientRow(String userId) {
    return _supabase
        .from('clients')
        .select('full_name, email, phone, created_at')
        .eq('id', userId)
        .maybeSingle();
  }

  /// Only the package the rider already pays for — never the plan catalogue.
  Future<Map<String, dynamic>?> activePackageRow(String userId) {
    return _supabase
        .from('subscriptions')
        .select('package_name, route_name, end_date')
        .eq('client_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Counts bookings server-side: the hub needs the number, not the rows.
  Future<int> bookingCount(
    String userId, {
    required List<String> statuses,
    String? fromDate,
  }) async {
    var query = _supabase
        .from('operation_bookings')
        .select('id')
        .eq('client_id', userId)
        .inFilter('status', statuses);

    if (fromDate != null) query = query.gte('trip_date', fromDate);

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  Future<void> updateClientRow(
    String userId, {
    required String name,
    required String email,
    required String phone,
  }) {
    return _supabase
        .from('clients')
        .update({
          'full_name': name,
          'email': email,
          'phone': phone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// The reads behind the profile hub, kept apart from the datasource so the
/// datasource reads as "what the hub needs" rather than as SQL.
class ProfileQueries {
  const ProfileQueries(this._supabase);

  final SupabaseClient _supabase;

  /// A trip's real lifecycle lives on `operation_trips.status`, not on the
  /// booking. `operation_bookings.status` only tracks payment/boarding
  /// (`draft | reserved | confirmed | boarded | completed | cancelled`) and
  /// never actually reaches `boarded` or `completed` in practice — completion
  /// stamps the trip, not the booking — so counting by the booking's own
  /// status always reads zero.
  ///
  /// This is every trip status short of `completed`/`cancelled`. The rider
  /// only sees two buckets on the hub, so a trip that has started boarding or
  /// is already in progress must still count as "upcoming" for them — it
  /// hasn't happened yet from their seat, even though the dashboard's own
  /// filters label that window "active" rather than "upcoming".
  static const upcomingTripStatuses = <String>[
    'scheduled',
    'open_for_booking',
    'boarding',
    'in_progress',
  ];

  /// Trips the rider actually travelled.
  static const completedTripStatuses = <String>['completed'];

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

  /// Counts bookings server-side by their trip's real status: the hub needs
  /// the number, not the rows. A cancelled booking never counts, whatever
  /// state its trip ended up in.
  Future<int> bookingCount(
    String userId, {
    required List<String> tripStatuses,
  }) async {
    final response = await _supabase
        .from('operation_bookings')
        // Aliased view embed: clients read trips through `public_trips` only.
        .select('id, operation_trips:public_trips!inner(status)')
        .eq('client_id', userId)
        .neq('status', 'cancelled')
        .inFilter('operation_trips.status', tripStatuses)
        .count(CountOption.exact);
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

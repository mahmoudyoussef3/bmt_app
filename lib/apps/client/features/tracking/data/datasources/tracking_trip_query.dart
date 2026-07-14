import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw Supabase reads behind one tracking session, kept separate from the
/// row→entity mapping so each stays readable.
class TrackingTripQuery {
  const TrackingTripQuery(this._client);

  final SupabaseClient _client;

  /// A booking is only trackable once its payment has actually been approved
  /// (`confirmed`/`boarded`/`completed`) — never while it is still `draft` or
  /// `reserved` (payment pending) or `cancelled` (payment rejected). Enforced
  /// here, not just by hiding the "Track" button, so that no entry point
  /// (explicit booking id, explicit trip id, or the "current active trip"
  /// lookup) can surface a live vehicle position before payment is approved.
  static const trackableStatuses = ['confirmed', 'boarded', 'completed'];

  Future<Map<String, dynamic>?> findBooking({
    required String userId,
    String? bookingId,
    String? tripId,
  }) async {
    final base = _client
        .from('operation_bookings')
        .select('id, trip_id, status, created_at')
        .eq('client_id', userId);

    if (bookingId != null && bookingId.isNotEmpty) {
      return _ifTrackable(await base.eq('id', bookingId).maybeSingle());
    }
    if (tripId != null && tripId.isNotEmpty) {
      return _ifTrackable(await base.eq('trip_id', tripId).maybeSingle());
    }
    return base
        .inFilter('status', trackableStatuses)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Map<String, dynamic>? _ifTrackable(Map<String, dynamic>? booking) =>
      trackableStatuses.contains(booking?['status']?.toString())
      ? booking
      : null;

  /// The trip's stops. `route_point_id` is selected so the rider's manifest
  /// points can be matched to stops by id rather than by name.
  Future<List<Map<String, dynamic>>> routePoints(String tripId) async {
    final rows = await _client
        .from('trip_route_points')
        .select(
          'id, route_point_id, point_name, point_order, latitude, longitude, '
          'arrival_offset, departure_offset',
        )
        .eq('trip_id', tripId)
        .order('point_order');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// `drivers.rating` / `vehicles.rating` are the real averages maintained by
  /// the `trip_reviews` triggers — the screen shows those, or nothing.
  Future<Map<String, dynamic>?> trip(String tripId) {
    return _client
        .from('operation_trips')
        .select('''
          id, trip_code, status, trip_date, departure_time, arrival_time,
          route:operation_routes(name),
          driver:drivers(full_name, phone, rating, rating_count),
          vehicle:vehicles(plate_number, vehicle_type, brand, model,
                           rating, rating_count)
        ''')
        .eq('id', tripId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> latestLocation(String tripId) {
    return _client
        .from('trip_live_locations')
        .select('latitude, longitude, heading, speed, accuracy, recorded_at')
        .eq('trip_id', tripId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// The rider's own manifest row: seat, boarding/drop-off point, and whether
  /// the captain checked them in. Deployments that hide the manifest from
  /// clients degrade to "we don't know" rather than failing the whole screen.
  Future<Map<String, dynamic>?> passenger(String tripId, String userId) async {
    try {
      return await _client
          .from('trip_passengers')
          .select(
            'seat_label, pickup_point_id, pickup_point_name, '
            'dropoff_point_id, dropoff_point_name, status',
          )
          .eq('trip_id', tripId)
          .eq('customer_id', userId)
          .limit(1)
          .maybeSingle();
    } on PostgrestException {
      return null;
    }
  }

  /// Newest first: the head drives state inference, and the per-station
  /// arrivals seed the progress engine's authoritative floor.
  Future<List<Map<String, dynamic>>> events(String tripId) async {
    try {
      final rows = await _client
          .from('trip_events')
          .select('title, created_at')
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);
      return (rows as List).cast<Map<String, dynamic>>();
    } on PostgrestException {
      // Some deployments don't expose operational event text to clients; trip
      // status and live location remain authoritative fallbacks.
      return const [];
    }
  }

  /// Whether this booking already has a review, so a completed trip only
  /// offers the review flow when there is still one to leave.
  Future<bool> hasReview(String bookingId) async {
    try {
      final row = await _client
          .from('trip_reviews')
          .select('booking_id')
          .eq('booking_id', bookingId)
          .maybeSingle();
      return row != null;
    } on PostgrestException {
      return false;
    }
  }
}

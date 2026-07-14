import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/home_data.dart';
import '../models/home_data_model.dart';
import 'home_datasource.dart';

class SupabaseHomeDatasource implements HomeDatasource {
  final SupabaseClient _supabase;

  const SupabaseHomeDatasource(this._supabase);

  static const _bookingColumns =
      'id, trip_id, booking_number, status, seat, trip_date, '
      'trip_time, route, payment_amount, pickup_point_name, dropoff_point_name';

  @override
  Stream<void> watchHomeChanges() {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    final channel = _supabase
        .channel('client_home_trips')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          callback: notify,
        )
        // A booking changing state — approved, rejected, boarded — changes what
        // Home must show about it, so it has to refetch on that too.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_bookings',
          callback: notify,
        )
        .subscribe();

    controller.onCancel = channel.unsubscribe;
    return controller.stream;
  }

  @override
  Future<HomeDataModel> getHomeData() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final user = _supabase.auth.currentUser;

    final responses = await Future.wait<dynamic>([
      _supabase
          .from('operation_routes')
          .select('id, name, start_city, end_city, duration, status')
          .eq('status', 'active'),
      _supabase
          .from('operation_trips')
          .select('''
            *,
            route:operation_routes(id, name, start_city, end_city, duration),
            trip_pricing(one_time_price, currency, is_active)
          ''')
          .gte('trip_date', today)
          .inFilter('status', ['open_for_booking', 'boarding'])
          .order('trip_date')
          .order('departure_time')
          .limit(50),
      if (user != null) _bookingsOf(user.id, today) else Future.value(const []),
      if (user != null) _activePackageOf(user.id) else Future.value(null),
    ]);

    final routesData = responses[0] as List<dynamic>;
    final tripsData = responses[1] as List<dynamic>;

    final bookings = (responses[2] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(HomeBookingMapper.fromRow)
        .nonNulls
        .toList();

    return HomeDataModel(
      upcomingTrips: _upcomingTrips(tripsData, bookings),
      bookings: bookings,
      pickupSuggestions: _distinct(routesData, 'start_city'),
      destinationSuggestions: _distinct(routesData, 'end_city'),
      timeSuggestions: _distinct(tripsData, 'departure_time'),
      userName:
          user?.userMetadata?['full_name']?.toString() ??
          user?.userMetadata?['name']?.toString() ??
          'User',
      activePackage: HomeActivePackageMapper.fromRow(
        responses[3] as Map<String, dynamic>?,
      ),
    );
  }

  /// The seats this rider still holds. `reserved | confirmed | boarded` is the
  /// live-commitment vocabulary of `operation_bookings.status`; a booking under
  /// payment review is `reserved`, and it must reach Home so the rider can see
  /// it rather than wonder whether it went through.
  Future<List<Map<String, dynamic>>> _bookingsOf(String userId, String today) {
    return _supabase
        .from('operation_bookings')
        .select(_bookingColumns)
        .eq('client_id', userId)
        .inFilter('status', HomeBookingStatus.liveStatuses)
        .gte('trip_date', today)
        .order('trip_date')
        .order('trip_time')
        .limit(10);
  }

  /// Home only surfaces a package the rider already pays for, so the
  /// subscription they own is all we need — never the plan catalogue.
  Future<Map<String, dynamic>?> _activePackageOf(String userId) {
    return _supabase
        .from('subscriptions')
        .select('package_name, route_name, start_date, end_date')
        .eq('client_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Trips arrive ordered by date then departure time, so the first few are the
  /// next seats a rider can actually take. Each is tagged with the rider's own
  /// booking on it, when they have one.
  List<UpcomingTripData> _upcomingTrips(
    List<dynamic> tripsData,
    List<HomeBookingData> bookings,
  ) {
    // A booking holds exactly one seat, so the seats a rider has on a departure
    // is the number of bookings they hold on it.
    final booked = <String, HomeBookingData>{};
    final bookedSeats = <String, int>{};
    for (final booking in bookings) {
      if (booking.tripId.isEmpty) continue;
      booked.putIfAbsent(booking.tripId, () => booking);
      bookedSeats.update(
        booking.tripId,
        (seats) => seats + 1,
        ifAbsent: () => 1,
      );
    }

    return tripsData.whereType<Map<String, dynamic>>().take(4).map((trip) {
      final tripId = trip['id']?.toString() ?? '';
      return UpcomingTripMapper.fromRow(
        trip,
        bookedStatus: booked[tripId]?.status,
        bookedSeats: bookedSeats[tripId] ?? 0,
      );
    }).toList();
  }

  List<String> _distinct(List<dynamic> rows, String column) {
    final values = <String>{};
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final value = row[column]?.toString().trim() ?? '';
      if (value.isNotEmpty) values.add(value);
    }
    return values.toList();
  }
}

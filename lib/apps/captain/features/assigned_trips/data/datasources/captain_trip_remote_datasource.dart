import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/captain/core/session/captain_driver_id_resolver.dart';
import 'package:bmt_app/core/tracking/progress/arrival_events.dart';

import '../../domain/entities/assigned_trip.dart';
import '../models/assigned_trip_model.dart';

class CaptainTripRemoteDataSource {
  CaptainTripRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  String? _cachedDriverId;

  Stream<void> watchTripUpdates() {
    final driverId = _cachedDriverId;
    if (driverId == null) return const Stream.empty();

    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _supabase
        .channel('captain_assigned_trips:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: notify,
        );

    for (final table in const [
      'operation_bookings',
      'trip_passengers',
      'trip_events',
      'trip_route_points',
      'trip_seats',
    ]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: notify,
      );
    }

    final subscribedChannel = channel.subscribe();
    controller.onCancel = subscribedChannel.unsubscribe;
    return controller.stream;
  }

  Future<List<AssignedTripModel>> getAssignedTrips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];

    _cachedDriverId = await resolveCaptainDriverId(_supabase, user);
    final driverId = _cachedDriverId;
    if (driverId == null) return const [];

    final today = _isoDate(DateTime.now());

    final response = await _supabase
        .from('operation_trips')
        .select('''
          *,
          operation_routes(name, start_city, end_city),
          vehicles(vehicle_code, plate_number),
          trip_route_points(id, point_name, point_order, latitude, longitude),
          trip_passengers(id, status),
          trip_events(title)
        ''')
        .eq('driver_id', driverId)
        // Trips still to drive (any day) plus today's already-completed ones —
        // otherwise a captain done for the day sees "no trips assigned" instead
        // of a day summary that accounts for what they already drove today.
        .or(
          'status.in.(scheduled,open_for_booking,boarding,in_progress),'
          'and(status.eq.completed,trip_date.eq.$today)',
        )
        .order('trip_date')
        .order('departure_time');

    return response.map<AssignedTripModel>(_mapTrip).toList();
  }

  String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  AssignedTripModel _mapTrip(Map<String, dynamic> json) {
    final route = json['operation_routes'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicles'] as Map<String, dynamic>? ?? {};
    final points =
        ((json['trip_route_points'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
          ..sort(
            (a, b) => ((a['point_order'] as int?) ?? 0).compareTo(
              (b['point_order'] as int?) ?? 0,
            ),
          );
    final passengers = (json['trip_passengers'] as List?) ?? const [];
    // scan_passenger_ticket writes 'confirmed' on check-in (see migration_07)
    // — trip_passengers.status has no 'boarded' value in its check
    // constraint. 'completed' is kept defensively; nothing currently writes
    // it, but it would mean the same thing if something one day did.
    final boarded = passengers.where((p) {
      final status = (p as Map<String, dynamic>)['status']?.toString();
      return status == 'confirmed' || status == 'completed';
    }).length;
    final tripDate = json['trip_date']?.toString() ?? '';

    final stops = points
        .map(
          (p) => AssignedTripStop(
            id: p['id']?.toString() ?? '',
            name: p['point_name']?.toString() ?? '',
            latitude: (p['latitude'] as num?)?.toDouble(),
            longitude: (p['longitude'] as num?)?.toDouble(),
          ),
        )
        .toList();
    final events = (json['trip_events'] as List?) ?? const [];
    final arrivalEventCount = countStationArrivalEvents(
      events.map((e) => (e as Map<String, dynamic>)['title'] as String?),
    );

    return AssignedTripModel(
      id: json['id']?.toString() ?? '',
      route:
          route['name']?.toString() ??
          '${route['start_city'] ?? ''} → ${route['end_city'] ?? ''}',
      vehicleNumber: vehicle['vehicle_code']?.toString() ?? '',
      plateNumber: vehicle['plate_number']?.toString() ?? '',
      departureTime: _dateTime(tripDate, json['departure_time']),
      expectedArrivalTime: _dateTime(tripDate, json['arrival_time']),
      stops: stops,
      passengerCount: passengers.length,
      boardedCount: boarded,
      status: _status(json['status']?.toString()),
      arrivedStationsCount: stationArrivalFloor(
        arrivalEventCount: arrivalEventCount,
        routePointCount: stops.length,
      ),
    );
  }

  DateTime _dateTime(String date, Object? time) {
    final parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    final parts = time?.toString().split(':') ?? const [];
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
  }

  AssignedTripStatus _status(String? value) {
    return switch (value) {
      'boarding' => AssignedTripStatus.boarding,
      'in_progress' => AssignedTripStatus.inProgress,
      'completed' => AssignedTripStatus.completed,
      _ => AssignedTripStatus.scheduled,
    };
  }
}

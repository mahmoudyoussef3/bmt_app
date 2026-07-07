import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import '../models/tracking_trip_model.dart';
import '../../domain/entities/tracking_trip.dart';

import 'dart:async';

abstract class TrackingDatasource {
  Future<TrackingTripDataModel> getTrackingTrip({
    String? bookingId,
    String? tripId,
  });

  Stream<TrackingPointModel> watchVehiclePosition(String tripId);

  Stream<void> watchTripChanges(String tripId);
}

class SupabaseTrackingDatasource implements TrackingDatasource {
  const SupabaseTrackingDatasource(this._client);

  final SupabaseClient _client;

  @override
  Stream<TrackingPointModel> watchVehiclePosition(String tripId) {
    final controller = StreamController<TrackingPointModel>.broadcast();
    final channel = _client
        .channel('location_updates:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'trip_live_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (change) {
            try {
              controller.add(
                TrackingPointModel.fromLiveLocationRow(change.newRecord),
              );
            } catch (_) {}
          },
        )
        .subscribe();
    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  @override
  Stream<void> watchTripChanges(String tripId) {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _client
        .channel('client_tracking:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: notify,
        );

    for (final table in const [
      'operation_bookings',
      'trip_events',
      'trip_passengers',
      'trip_route_points',
      'trip_seats',
    ]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'trip_id',
          value: tripId,
        ),
        callback: notify,
      );
    }

    final subscribedChannel = channel.subscribe();
    controller.onCancel = subscribedChannel.unsubscribe;
    return controller.stream;
  }

  @override
  Future<TrackingTripDataModel> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _emptyModel();

    final booking = await _findBooking(
      userId: userId,
      bookingId: bookingId,
      tripId: tripId,
    );

    if (booking == null) return _emptyModel();
    final resolvedTripId = booking['trip_id'] as String?;
    if (resolvedTripId == null) return _emptyModel();

    final results = await Future.wait<dynamic>([
      _client
          .from('trip_route_points')
          .select(
            'id, latitude, longitude, point_name, point_order, '
            'arrival_offset, departure_offset',
          )
          .eq('trip_id', resolvedTripId)
          .order('point_order'),
      _client
          .from('operation_trips')
          .select('''
            id, trip_code, status, trip_date, departure_time, arrival_time,
            route:operation_routes(name),
            driver:drivers(full_name, phone),
            vehicle:vehicles(vehicle_code, plate_number, vehicle_type, brand, model)
          ''')
          .eq('id', resolvedTripId)
          .maybeSingle(),
      _client
          .from('trip_live_locations')
          .select('latitude, longitude, heading, speed, accuracy, recorded_at')
          .eq('trip_id', resolvedTripId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      _getLatestTripEvent(resolvedTripId),
      _getPassengerRow(resolvedTripId, userId),
    ]);

    final pointRows = (results[0] as List?) ?? [];
    final tripRow = results[1] as Map<String, dynamic>?;
    final locRow = results[2] as Map<String, dynamic>?;
    final latestEvent = results[3] as Map<String, dynamic>?;
    final passengerRow = results[4] as Map<String, dynamic>?;

    final routePoints = pointRows.map((r) {
      final m = r as Map<String, dynamic>;
      return TrackingPointModel(
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    final stops = pointRows
        .map((r) => (r as Map<String, dynamic>)['point_name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final tripStatus = tripRow?['status'] as String? ?? '';
    final state = _mapTripState(
      tripStatus,
      hasLiveLocation: locRow != null,
      latestEventTitle: latestEvent?['title']?.toString(),
    );
    final tripDate = tripRow?['trip_date']?.toString();
    final departureAt = _combineDateAndTime(
      tripDate,
      tripRow?['departure_time']?.toString(),
    );
    final arrivalAt = _combineDateAndTime(
      tripDate,
      tripRow?['arrival_time']?.toString(),
    );
    final routeStops = _buildRouteStops(pointRows, tripDate, departureAt);
    final route = tripRow?['route'] as Map<String, dynamic>?;
    final driver = tripRow?['driver'] as Map<String, dynamic>?;
    final vehicle = tripRow?['vehicle'] as Map<String, dynamic>?;

    return TrackingTripDataModel(
      routePoints: routePoints,
      timelineSteps: _buildTimeline(state),
      stops: stops.isEmpty ? const ['Origin', 'Destination'] : stops,
      tripState: state,
      routeStops: routeStops,
      passengerPickupName: passengerRow?['pickup_point_name']?.toString(),
      passengerDropoffName: passengerRow?['dropoff_point_name']?.toString(),
      passengerStatus: passengerRow?['status']?.toString(),
      tripId: resolvedTripId,
      bookingId: booking['id']?.toString(),
      routeName: route?['name']?.toString(),
      pickupName: stops.isNotEmpty ? stops.first : null,
      destinationName: stops.length > 1 ? stops.last : null,
      departureAt: departureAt,
      arrivalAt: arrivalAt,
      driverName: driver?['full_name']?.toString(),
      driverPhone: driver?['phone']?.toString(),
      vehicleName: [
        vehicle?['brand']?.toString(),
        vehicle?['model']?.toString(),
      ].where((part) => part != null && part.trim().isNotEmpty).join(' '),
      vehicleType: vehicle?['vehicle_type']?.toString(),
      vehiclePlate: vehicle?['plate_number']?.toString(),
      vehicleLatitude: locRow != null
          ? (locRow['latitude'] as num?)?.toDouble()
          : null,
      vehicleLongitude: locRow != null
          ? (locRow['longitude'] as num?)?.toDouble()
          : null,
      vehicleHeading: locRow != null
          ? (locRow['heading'] as num?)?.toDouble()
          : null,
      vehicleSpeed: locRow != null
          ? (locRow['speed'] as num?)?.toDouble()
          : null,
      vehicleAccuracy: locRow != null
          ? (locRow['accuracy'] as num?)?.toDouble()
          : null,
      vehicleLocationAt: locRow?['recorded_at'] != null
          ? DateTime.tryParse(locRow!['recorded_at'].toString())?.toLocal()
          : null,
    );
  }

  Future<Map<String, dynamic>?> _findBooking({
    required String userId,
    String? bookingId,
    String? tripId,
  }) async {
    var query = _client
        .from('operation_bookings')
        .select('id, trip_id, status, created_at')
        .eq('client_id', userId);

    if (bookingId != null && bookingId.isNotEmpty) {
      return query.eq('id', bookingId).maybeSingle();
    }

    if (tripId != null && tripId.isNotEmpty) {
      return query.eq('trip_id', tripId).maybeSingle();
    }

    return query
        .inFilter('status', [
          'newRequest',
          'paymentUploaded',
          'underReview',
          'approved',
          'confirmed',
        ])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// The rider's own manifest row (pickup/dropoff point + boarding status).
  /// Deployments that hide the manifest from clients degrade gracefully.
  Future<Map<String, dynamic>?> _getPassengerRow(
    String tripId,
    String userId,
  ) async {
    try {
      return await _client
          .from('trip_passengers')
          .select('pickup_point_name, dropoff_point_name, status')
          .eq('trip_id', tripId)
          .eq('customer_id', userId)
          .limit(1)
          .maybeSingle();
    } on PostgrestException {
      return null;
    }
  }

  List<RouteStop> _buildRouteStops(
    List<dynamic> pointRows,
    String? tripDate,
    DateTime? departureAt,
  ) {
    return pointRows.map((r) {
      final m = r as Map<String, dynamic>;
      return RouteStop(
        id: m['id']?.toString(),
        name: m['point_name'] as String? ?? '',
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
        order: m['point_order'] as int? ?? 0,
        plannedArrival: _stopTime(
          tripDate,
          m['arrival_offset']?.toString(),
          departureAt,
        ),
        plannedDeparture: _stopTime(
          tripDate,
          m['departure_offset']?.toString(),
          departureAt,
        ),
      );
    }).toList();
  }

  /// Resolves a stop's "HH:mm" clock time against the trip date. Times more
  /// than 6 h before departure belong to a run that crosses midnight and
  /// roll forward one day.
  DateTime? _stopTime(String? date, String? clockTime, DateTime? departureAt) {
    final parsed = _combineDateAndTime(date, clockTime);
    if (parsed == null || departureAt == null) return parsed;
    return departureAt.difference(parsed).inHours >= 6
        ? parsed.add(const Duration(days: 1))
        : parsed;
  }

  Future<Map<String, dynamic>?> _getLatestTripEvent(String tripId) async {
    try {
      return await _client
          .from('trip_events')
          .select('title, created_at')
          .eq('trip_id', tripId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } on PostgrestException {
      // Some deployments may not expose operational event text to clients.
      // Trip status and location remain authoritative fallbacks.
      return null;
    }
  }

  TrackingTripState _mapTripState(
    String tripStatus, {
    required bool hasLiveLocation,
    String? latestEventTitle,
  }) {
    return switch (tripStatus) {
      'in_progress' => TrackingTripState.inProgress,
      'boarding' => TrackingTripState.boarding,
      'completed' => TrackingTripState.completed,
      'open_for_booking' || 'scheduled' => _stateFromEvent(
        latestEventTitle,
        hasLiveLocation: hasLiveLocation,
      ),
      _ => _stateFromEvent(latestEventTitle, hasLiveLocation: hasLiveLocation),
    };
  }

  TrackingTripState _stateFromEvent(
    String? title, {
    required bool hasLiveLocation,
  }) {
    return switch (title) {
      'اكتملت الرحلة' || 'وصلت الرحلة للوجهة' => TrackingTripState.completed,
      'غادرت الرحلة' => TrackingTripState.inProgress,
      'صعود الركاب' ||
      'وصل السائق لنقطة الانطلاق' => TrackingTripState.boarding,
      'السائق في الطريق' => TrackingTripState.driverOnWay,
      _ =>
        hasLiveLocation
            ? TrackingTripState.driverOnWay
            : TrackingTripState.notStarted,
    };
  }

  DateTime? _combineDateAndTime(String? date, String? time) {
    if (date == null || date.isEmpty || time == null || time.isEmpty) {
      return null;
    }
    return DateTime.tryParse('${date}T$time')?.toLocal();
  }

  List<String> _buildTimeline(TrackingTripState state) => const [
    'Booking confirmed',
    'Driver on the way',
    'Boarding',
    'Trip started',
    'Arrived',
  ];

  TrackingTripDataModel _emptyModel() => const TrackingTripDataModel(
    routePoints: [],
    timelineSteps: [
      'Booking confirmed',
      'Driver on the way',
      'Boarding',
      'Trip started',
      'Arrived',
    ],
    stops: [],
    tripState: TrackingTripState.notStarted,
  );
}

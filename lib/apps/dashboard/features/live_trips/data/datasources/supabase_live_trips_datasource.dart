import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_engine.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import '../../domain/entities/live_trip.dart';
import 'live_trips_datasource.dart';

class SupabaseLiveTripsDatasource implements LiveTripsDatasource {
  const SupabaseLiveTripsDatasource(this._client);

  final SupabaseClient _client;

  static const _tripSelectWithDetails = '''
    id, trip_code, route_id, driver_id, vehicle_id, status,
    departure_time, trip_date, passenger_count, booked_seats, capacity,
    route:operation_routes(name),
    driver:drivers(full_name, phone),
    vehicle:vehicles(plate_number, vehicle_type),
    route_points:trip_route_points(id, point_name, point_order, latitude, longitude, arrival_offset, departure_offset),
    passengers:trip_passengers(id, status, passenger_name, phone, pickup_point_name),
    events:trip_events(id, title, description, done, created_at)
  ''';

  @override
  Future<List<LiveTrip>> getLiveTrips() async {
    try {
      final response = await _client
          .from('operation_trips')
          .select(_tripSelectWithDetails)
          .inFilter('status', ['open_for_booking', 'boarding', 'in_progress'])
          .order('departure_time');

      final trips = (response as List)
          .map(
            (json) => _mapToLiveTrip(
              json as Map<String, dynamic>,
              includeDetails: true,
            ),
          )
          .toList();

      return _attachLatestLocations(trips);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<LiveTrip>> _attachLatestLocations(List<LiveTrip> trips) async {
    if (trips.isEmpty) return trips;
    final tripIds = trips.map((t) => t.id).toList();
    try {
      final locs = await _client
          .from('trip_live_locations')
          .select(
            'trip_id, latitude, longitude, heading, speed, accuracy, recorded_at',
          )
          .inFilter('trip_id', tripIds)
          .order('recorded_at', ascending: false);

      final latestByTrip = <String, Map<String, dynamic>>{};
      for (final loc in (locs as List)) {
        final m = loc as Map<String, dynamic>;
        final tid = m['trip_id'] as String;
        latestByTrip.putIfAbsent(tid, () => m);
      }

      return trips.map((t) {
        final loc = latestByTrip[t.id];
        final withLocation = loc == null
            ? t
            : t.copyWith(vehiclePosition: _mapPosition(loc));
        return _withSmartProgress(withLocation);
      }).toList();
    } catch (_) {
      return trips.map(_withSmartProgress).toList();
    }
  }

  @override
  Future<LiveTrip> getLiveTripDetails(String tripId) async {
    try {
      final results = await Future.wait([
        _client
            .from('operation_trips')
            .select(_tripSelectWithDetails)
            .eq('id', tripId)
            .single(),
        _client
            .from('trip_live_locations')
            .select('latitude, longitude, heading, speed, accuracy, recorded_at')
            .eq('trip_id', tripId)
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle(),
      ]);

      final trip = _mapToLiveTrip(
        results[0] as Map<String, dynamic>,
        includeDetails: true,
      );
      final locRow = results[1];
      if (locRow == null) return _withSmartProgress(trip);
      return _withSmartProgress(
        trip.copyWith(vehiclePosition: _mapPosition(locRow)),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> startTrip(String tripId) async {
    try {
      final current = await _client
          .from('operation_trips')
          .select('status')
          .eq('id', tripId)
          .single();
      final currentStatus = current['status']?.toString() ?? '';
      final nextStatus = switch (currentStatus) {
        'open_for_booking' => 'boarding',
        'boarding' => 'in_progress',
        'scheduled' => 'open_for_booking',
        _ => throw Exception(
          'لا يمكن بدء الرحلة من الحالة الحالية: $currentStatus',
        ),
      };

      await _client.rpc(
        'update_trip_status',
        params: {'p_trip_id': tripId, 'p_new_status': nextStatus},
      );
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> pauseTrip(String tripId) async {
    throw Exception('الإيقاف المؤقت غير مدعوم في دورة حياة الرحلات الحالية.');
  }

  @override
  Future<LiveTrip> resumeTrip(String tripId) async {
    throw Exception('استئناف الرحلة غير مدعوم لأن الإيقاف المؤقت غير مفعل.');
  }

  @override
  Future<LiveTrip> completeTrip(String tripId) async {
    try {
      await _client.rpc(
        'update_trip_status',
        params: {'p_trip_id': tripId, 'p_new_status': 'completed'},
      );
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> markPointArrived(String tripId, String pointId) async {
    try {
      final point = await _pointName(tripId, pointId);
      await _insertEvent(tripId, 'وصول محطة', 'وصلت الرحلة إلى محطة: $point');
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> markPointCompleted(String tripId, String pointId) async {
    try {
      final point = await _pointName(tripId, pointId);
      await _insertEvent(tripId, 'مغادرة محطة', 'غادرت الرحلة محطة: $point');
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> skipPoint(String tripId, String pointId) async {
    try {
      final point = await _pointName(tripId, pointId);
      await _insertEvent(
        tripId,
        'تخطي محطة',
        'تم تخطي محطة: $point',
        done: false,
      );
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> resolveAlert(String tripId, String alertId) async {
    try {
      await _client
          .from('trip_events')
          .update({'done': true})
          .eq('id', alertId)
          .eq('trip_id', tripId);
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LiveTrip> reportAlert({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      await _insertEvent(tripId, title, message, done: false);
      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<String> callDriver(String driverPhone) async {
    // Return the tel: URI — the UI layer calls url_launcher.
    return 'tel:$driverPhone';
  }

  @override
  Future<String> sendDriverMessage(String driverPhone, String message) async {
    return 'sms:$driverPhone?body=${Uri.encodeComponent(message)}';
  }

  @override
  Future<LiveTrip> togglePassengerCheckin(
    String tripId,
    String passengerId,
  ) async {
    try {
      final existing = await _client
          .from('trip_passengers')
          .select('status')
          .eq('id', passengerId)
          .single();

      final currentStatus = existing['status'] as String;
      // Toggle between confirmed and reserved
      final newStatus = currentStatus == 'confirmed' ? 'reserved' : 'confirmed';

      await _client
          .from('trip_passengers')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', passengerId);

      return getLiveTripDetails(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<void> watchTripStatusChanges() {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _client
        .channel('dashboard_live_trips')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
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
        callback: notify,
      );
    }

    final subscribedChannel = channel.subscribe();
    controller.onCancel = subscribedChannel.unsubscribe;
    return controller.stream;
  }

  @override
  Stream<VehiclePosition> watchVehiclePosition(String tripId) {
    final controller = StreamController<VehiclePosition>.broadcast();
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
              controller.add(_mapPosition(change.newRecord));
            } catch (_) {}
          },
        )
        .subscribe();
    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  // ── helpers ──────────────────────────────────────────────────────────

  Future<String> _pointName(String tripId, String pointId) async {
    final row = await _client
        .from('trip_route_points')
        .select('point_name')
        .eq('id', pointId)
        .eq('trip_id', tripId)
        .maybeSingle();
    return row?['point_name'] as String? ?? pointId;
  }

  Future<void> _insertEvent(
    String tripId,
    String title,
    String description, {
    bool done = true,
  }) async {
    await _client.from('trip_events').insert({
      'trip_id': tripId,
      'title': title,
      'description': description,
      'done': done,
    });
  }

  /// Layers geometric route progress on top of the event-based floor: the
  /// operator's per-station arrival log seeds the engine, then the latest
  /// GPS fix advances continuous progress, per-stop states, and ETAs.
  LiveTrip _withSmartProgress(LiveTrip trip) {
    if (trip.status == LiveTripStatus.cancelled || trip.routePoints.isEmpty) {
      return trip;
    }
    final phase = switch (trip.status) {
      LiveTripStatus.notStarted => TripProgressPhase.headingToPickup,
      LiveTripStatus.preparing => TripProgressPhase.boarding,
      LiveTripStatus.inProgress ||
      LiveTripStatus.paused => TripProgressPhase.enRoute,
      _ => TripProgressPhase.completed,
    };
    final engine = RouteProgressEngine(
      stops: [
        for (final p in trip.routePoints)
          RouteStop(
            id: p.id,
            name: p.name,
            latitude: p.latitude,
            longitude: p.longitude,
            order: p.order,
            plannedArrival: p.plannedArrivalTime,
          ),
      ],
      phase: phase,
      scheduledDeparture: trip.scheduledStartTime,
    );
    final arrivalFloor = trip.routePoints
        .where((p) => p.status == LivePointStatus.completed)
        .length;
    if (arrivalFloor > 0) engine.seedVisited(arrivalFloor);
    final position = trip.vehiclePosition;
    if (position != null) {
      // Receipt time = the fix timestamp, so hours-old rows read as stale.
      engine.addFix(
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: position.speed == null || position.speed! < 0
            ? null
            : position.speed! * 3.6,
        now: position.updatedAt,
      );
    }
    final snapshot = engine.snapshot(DateTime.now());
    final progressById = {
      for (final stop in snapshot.stops)
        if (stop.stop.id != null) stop.stop.id!: stop,
    };
    final points = [
      for (final p in trip.routePoints)
        _mergePointProgress(p, progressById[p.id], trip.status),
    ];
    var currentIdx = points.indexWhere(
      (p) =>
          p.status == LivePointStatus.arrived ||
          p.status == LivePointStatus.current,
    );
    if (currentIdx < 0) currentIdx = trip.currentPointIndex;
    return trip.copyWith(
      progressPercent: (snapshot.routeFraction * 100).round(),
      routePoints: points,
      currentPointIndex: currentIdx,
      expectedArrivalTime:
          snapshot.etaToDestination ?? trip.expectedArrivalTime,
    );
  }

  LiveRoutePoint _mergePointProgress(
    LiveRoutePoint point,
    StopProgress? progress,
    LiveTripStatus tripStatus,
  ) {
    if (progress == null) return point; // Point without valid coordinates.
    final status = switch (progress.status) {
      StopVisitStatus.departed => LivePointStatus.completed,
      StopVisitStatus.arrived => LivePointStatus.arrived,
      StopVisitStatus.next =>
        tripStatus == LiveTripStatus.inProgress
            ? LivePointStatus.current
            : LivePointStatus.pending,
      StopVisitStatus.upcoming => LivePointStatus.pending,
    };
    return point.copyWith(
      status: status,
      estimatedArrival: progress.eta,
      clearEstimatedArrival: progress.eta == null,
    );
  }

  VehiclePosition _mapPosition(Map<String, dynamic> loc) {
    return VehiclePosition(
      latitude: (loc['latitude'] as num).toDouble(),
      longitude: (loc['longitude'] as num).toDouble(),
      heading: loc['heading'] != null
          ? (loc['heading'] as num).toDouble()
          : null,
      speed: loc['speed'] != null ? (loc['speed'] as num).toDouble() : null,
      accuracy: loc['accuracy'] != null
          ? (loc['accuracy'] as num).toDouble()
          : null,
      updatedAt: loc['recorded_at'] != null
          ? DateTime.tryParse(loc['recorded_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
    );
  }

  LiveTrip _mapToLiveTrip(
    Map<String, dynamic> json, {
    bool includeDetails = false,
  }) {
    final routeJson = json['route'] as Map<String, dynamic>?;
    final driverJson = json['driver'] as Map<String, dynamic>?;
    final vehicleJson = json['vehicle'] as Map<String, dynamic>?;
    final events = (json['events'] as List?) ?? [];
    final routePointsList = (json['route_points'] as List?) ?? [];
    final passengersList = (json['passengers'] as List?) ?? [];

    final statusStr = json['status'] as String? ?? 'scheduled';
    final liveTripStatus = _mapStatus(statusStr);

    final dateStr = json['trip_date'] as String?;
    final timeStr = json['departure_time'] as String?;
    final scheduledTime = dateStr != null && timeStr != null
        ? DateTime.tryParse('${dateStr}T$timeStr') ?? DateTime.now()
        : DateTime.now();

    // Compute progress from completed arrival events
    final arrivalEventCount = events
        .where((e) => (e as Map<String, dynamic>)['title'] == 'وصول محطة')
        .length;
    final totalPoints = includeDetails ? routePointsList.length : 0;
    final currentIdx = arrivalEventCount.clamp(
      0,
      totalPoints > 0 ? totalPoints - 1 : 0,
    );
    final progress = totalPoints > 1
        ? ((currentIdx / (totalPoints - 1)) * 100).round().clamp(0, 100)
        : 0;

    // Unresolved events = active alerts
    final activeAlerts = events
        .where((e) => !((e as Map<String, dynamic>)['done'] as bool? ?? true))
        .toList();

    final now = DateTime.now();
    final isLate =
        liveTripStatus == LiveTripStatus.preparing &&
        scheduledTime.isBefore(now.subtract(const Duration(minutes: 10)));
    final health = activeAlerts.isNotEmpty
        ? LiveTripHealth.warning
        : isLate
        ? LiveTripHealth.delayed
        : LiveTripHealth.normal;

    final mappedPoints = routePointsList.asMap().entries.map((entry) {
      final idx = entry.key;
      final point = entry.value as Map<String, dynamic>;
      LivePointStatus pointStatus;
      if (idx < currentIdx) {
        pointStatus = LivePointStatus.completed;
      } else if (idx == currentIdx &&
          liveTripStatus == LiveTripStatus.inProgress) {
        pointStatus = LivePointStatus.current;
      } else {
        pointStatus = LivePointStatus.pending;
      }
      final pointName = point['point_name'] as String? ?? '';
      return LiveRoutePoint(
        id: point['id'] as String,
        name: pointName,
        latitude: (point['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (point['longitude'] as num?)?.toDouble() ?? 0,
        order: point['point_order'] as int? ?? idx,
        status: pointStatus,
        plannedArrivalTime: _pointTime(
          dateStr,
          point['arrival_offset']?.toString(),
        ),
        waitingPassengersCount: _passengersAtStop(
          passengersList,
          pointName,
          boarded: false,
        ),
        boardedPassengersCount: _passengersAtStop(
          passengersList,
          pointName,
          boarded: true,
        ),
      );
    }).toList();

    final mappedPassengers = passengersList.map((p) {
      final pMap = p as Map<String, dynamic>;
      // Check if passenger status is confirmed (checked in)
      final isCheckedIn = pMap['status'] == 'confirmed';
      return LivePassengerCheckin(
        id: pMap['id'] as String,
        passengerName: pMap['passenger_name'] as String? ?? '',
        passengerPhone: pMap['phone'] as String? ?? '',
        pickupPointName: pMap['pickup_point_name'] as String? ?? '',
        checkedIn: isCheckedIn,
        checkedInAt: isCheckedIn ? DateTime.now() : null,
      );
    }).toList();

    final mappedAlerts = activeAlerts.map((e) {
      final eMap = e as Map<String, dynamic>;
      return LiveTripAlert(
        id: eMap['id'] as String,
        type: LiveTripAlertType.delay,
        severity: LiveTripAlertSeverity.warning,
        title: eMap['title'] as String? ?? '',
        message: eMap['description'] as String? ?? '',
        createdAt: eMap['created_at'] != null
            ? DateTime.tryParse(eMap['created_at'] as String)?.toLocal() ??
                  DateTime.now()
            : DateTime.now(),
        resolved: eMap['done'] as bool? ?? false,
      );
    }).toList();

    final bookedSeats = json['booked_seats'] as int? ?? 0;
    final checkedInCount = mappedPassengers.where((p) => p.checkedIn).length;

    return LiveTrip(
      id: json['id'] as String,
      tripCode: json['trip_code'] as String? ?? '',
      routeId: json['route_id'] as String? ?? '',
      routeName: routeJson?['name'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      driverName: driverJson?['full_name'] as String? ?? '',
      driverPhone: driverJson?['phone'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      vehiclePlate: vehicleJson?['plate_number'] as String? ?? '',
      vehicleType: vehicleJson?['vehicle_type'] as String? ?? '',
      status: liveTripStatus,
      health: health,
      passengersCount: bookedSeats,
      checkedInPassengersCount: checkedInCount,
      missingPassengersCount: (bookedSeats - checkedInCount).clamp(
        0,
        bookedSeats,
      ),
      progressPercent: progress,
      scheduledStartTime: scheduledTime,
      routePoints: mappedPoints,
      currentPointIndex: currentIdx,
      alerts: mappedAlerts,
      passengers: mappedPassengers,
    );
  }

  /// Resolves a stop's "HH:mm" clock time against the trip date.
  DateTime? _pointTime(String? date, String? clockTime) {
    if (date == null || clockTime == null || clockTime.isEmpty) return null;
    return DateTime.tryParse('${date}T$clockTime');
  }

  /// Passenger flow per stop: manifest rows whose pickup point matches the
  /// stop name. `confirmed` means the captain checked the passenger in.
  int _passengersAtStop(
    List<dynamic> passengers,
    String pointName, {
    required bool boarded,
  }) {
    final needle = pointName.trim().toLowerCase();
    if (needle.isEmpty) return 0;
    var count = 0;
    for (final p in passengers) {
      final m = p as Map<String, dynamic>;
      final pickup = (m['pickup_point_name'] as String? ?? '')
          .trim()
          .toLowerCase();
      if (pickup != needle) continue;
      final status = m['status'] as String? ?? '';
      if (status == 'cancelled' || status == 'no_show') continue;
      if ((status == 'confirmed') == boarded) count++;
    }
    return count;
  }

  LiveTripStatus _mapStatus(String status) => switch (status) {
    'boarding' => LiveTripStatus.preparing,
    'in_progress' => LiveTripStatus.inProgress,
    'completed' => LiveTripStatus.completed,
    'cancelled' => LiveTripStatus.cancelled,
    _ => LiveTripStatus.notStarted,
  };

  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      return Exception('خطأ في مراقبة الرحلات: ${error.message}');
    }
    return Exception(error.toString());
  }
}

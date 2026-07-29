import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/session/dashboard_session.dart';
import '../../../trip_creation/domain/entities/trip_driver_option.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../shared/data/models/operation_trip_model.dart';
import '../../../shared/data/models/trip_pricing_model.dart';

import 'trips_datasource.dart';

class SupabaseTripsDatasource implements TripsDatasource {
  final SupabaseClient _client;
  final DashboardSession _session;

  const SupabaseTripsDatasource(this._client, this._session);

  @override
  Future<List<OperationTripModel>> fetchTrips() async {
    try {
      final response = await _client
          .from('operation_trips')
          .select('''
            *,
            route:operation_routes(id, name),
            driver:drivers(id, full_name),
            vehicle:vehicles(id, plate_number, vehicle_code, vehicle_type),
            route_points:trip_route_points(*),
            seats:trip_seats(*),
            passengers:trip_passengers(*),
            events:trip_events(*)
          ''')
          .eq('office_id', _session.officeId)
          .order('trip_date', ascending: false)
          .order('departure_time', ascending: false);

      return (response as List)
          .map(
            (json) => OperationTripModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> fetchTripById(String tripId) async {
    try {
      final response = await _client
          .from('operation_trips')
          .select('''
            *,
            route:operation_routes(id, name),
            driver:drivers(id, full_name),
            vehicle:vehicles(id, plate_number, vehicle_code, vehicle_type),
            route_points:trip_route_points(*),
            seats:trip_seats(*),
            passengers:trip_passengers(*),
            events:trip_events(*)
          ''')
          .eq('id', tripId)
          .single();

      return OperationTripModel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> createTrip(CreateTripInput input) async {
    try {
      // 1. Fetch route stations (client-side; used to build the snapshot array)
      final stationsResponse = await _client
          .from('route_stations')
          .select()
          .eq('route_id', input.routeId)
          .order('sort_order', ascending: true);

      final stations = stationsResponse as List;
      if (stations.isEmpty) {
        throw Exception('لا يمكن إنشاء رحلة لمسار ليس له محطات.');
      }

      // 2. Build route points array (preserving custom time overrides)
      final List<Map<String, dynamic>> routePoints = [];
      for (final station in stations) {
        final stId = station['id']?.toString();
        String arrivalOffset = station['arrival_offset']?.toString() ?? '';
        String departureOffset = station['departure_offset']?.toString() ?? '';

        if (input.customStationTimes.isNotEmpty) {
          final override = input.customStationTimes.firstWhere(
            (e) => e['route_point_id'] == stId,
            orElse: () => <String, String>{},
          );
          if (override.isNotEmpty) {
            final ca = override['arrival_offset'];
            final cd = override['departure_offset'];
            if (ca != null && ca.isNotEmpty) arrivalOffset = ca;
            if (cd != null && cd.isNotEmpty) departureOffset = cd;
          }
        }

        routePoints.add({
          'route_point_id': stId,
          'point_name': station['name'],
          'point_order': station['sort_order'],
          'arrival_offset': arrivalOffset,
          'departure_offset': departureOffset,
          'latitude': station['latitude'],
          'longitude': station['longitude'],
        });
      }

      // 3. Single atomic RPC call — all inserts in one transaction.
      //    If any insert fails the entire trip creation rolls back.
      //
      //    No vehicle, no capacity and no seat array are sent. Since
      //    20260731090000_driver_vehicle_authority the server resolves the vehicle from
      //    the driver's active assignment and derives the trip's capacity and seat map
      //    from that vehicle. This method used to assemble a seat array here — from the
      //    vehicle's stored configuration, or from a blueprint, or from a bare 3-wide
      //    grid — and post it alongside a vehicle id the operator had picked
      //    independently of the driver. Both were the client deciding things only the
      //    fleet can know.
      //
      //    office_create_trip also validates that the route and driver belong to this
      //    office and mints the trip code server-side.
      final rpcResult = await _client.rpc(
        'office_create_trip',
        params: {
          'p_route_id': input.routeId,
          'p_driver_id': input.driverId,
          'p_trip_date': input.date,
          'p_departure_time': input.departure,
          'p_arrival_time': input.arrival,
          'p_ticket_price': input.ticketPrice,
          'p_currency': input.currency,
          'p_notes': ['تم إنشاء الرحلة ونمذجة المحطات والمقاعد تلقائياً'],
          'p_route_points': routePoints,
        },
      );

      final tripId = (rpcResult as Map<String, dynamic>)['trip_id'] as String;

      // 5. Fetch the fully assembled trip to return to the cubit
      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> updateTripInfo(OperationTrip trip) async {
    try {
      // `status` is deliberately absent. Writing it here was a direct table update that
      // skipped the state machine entirely — any status to any status, with none of the
      // side effects or notifications. Since migration 20260727160000 the database
      // rejects it outright; status moves through updateTripStatus.
      await _client
          .from('operation_trips')
          .update({
            'driver_id': trip.driverId,
            'vehicle_id': trip.vehicleId,
            'trip_date': trip.date,
            'departure_time': trip.departure,
            'arrival_time': trip.arrival.isEmpty ? null : trip.arrival,
            'ticket_price': trip.ticketPrice,
            'currency': trip.currency,
          })
          .eq('id', trip.id);

      await logEvent(
        trip.id,
        'تعديل تفاصيل الرحلة',
        'تم تحديث السائق أو المركبة أو أوقات الانطلاق للرحلة.',
      );

      return await fetchTripById(trip.id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _client.from('operation_trips').delete().eq('id', tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'office_update_trip_status',
        params: {
          'p_trip_id': tripId,
          'p_new_status': status.dbValue,
          'p_reason': reason,
        },
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> cancelTrip(String tripId, String reason) async {
    try {
      await _client.rpc(
        'office_cancel_trip',
        params: {'p_trip_id': tripId, 'p_reason': reason},
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'office_close_stale_trip',
        params: {
          'p_trip_id': tripId,
          'p_outcome': outcome.dbValue,
          'p_reason': reason,
        },
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) async {
    try {
      // Fetch current seat info to log
      final seatResponse = await _client
          .from('trip_seats')
          .select('seat_label')
          .eq('id', seatId)
          .single();
      final label = seatResponse['seat_label'] as String;

      await _client
          .from('trip_seats')
          .update({
            'state': state.name,
            // If seat is blocked or available, clear passenger
            if (state == TripSeatState.available ||
                state == TripSeatState.blocked)
              'passenger_id': null,
          })
          .eq('id', seatId);

      await logEvent(
        tripId,
        'تعديل حالة المقعد',
        'تم تغيير حالة المقعد $label إلى: ${state.label}.',
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) async {
    try {
      await _client
          .from('trip_passengers')
          .update({
            'passenger_name': passenger.name,
            'phone': passenger.phone,
            'status': passenger.status,
          })
          .eq('id', passenger.id);

      await logEvent(
        tripId,
        'تحديث بيانات راكب',
        'تم تحديث الاسم ورقم الهاتف للراكب ${passenger.name}.',
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> cancelPassenger(
    String tripId,
    String passengerId,
  ) async {
    try {
      // Find the passenger record to find the seat and log details
      final pResponse = await _client
          .from('trip_passengers')
          .select('passenger_name, seat_id')
          .eq('id', passengerId)
          .single();

      final name = pResponse['passenger_name'] as String;
      final seatId = pResponse['seat_id'] as String?;

      // Update passenger status to canceled
      await _client
          .from('trip_passengers')
          .update({'status': 'cancelled'})
          .eq('id', passengerId);

      // Free the seat
      if (seatId != null) {
        await _client
            .from('trip_seats')
            .update({'state': 'available', 'passenger_id': null})
            .eq('id', seatId);
      }

      await logEvent(
        tripId,
        'إلغاء حجز راكب',
        'تم إلغاء حجز الراكب $name وتحرير مقعده تلقائياً.',
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) async {
    try {
      // 1. Fetch passenger and target seat
      final pResponse = await _client
          .from('trip_passengers')
          .select('passenger_name, seat_id, status')
          .eq('id', passengerId)
          .single();
      final passengerName = pResponse['passenger_name'] as String;
      final oldSeatId = pResponse['seat_id'] as String?;
      final passengerStatus = pResponse['status'] as String? ?? 'reserved';

      final seatResponse = await _client
          .from('trip_seats')
          .select('id, state')
          .eq('trip_id', tripId)
          .eq('seat_label', seatLabel)
          .single();
      final newSeatId = seatResponse['id'] as String;
      final newSeatState = seatResponse['state'] as String;

      if (newSeatState != 'available') {
        throw Exception('المقعد المطلوب غير متاح حالياً.');
      }

      // 2. Free old seat
      if (oldSeatId != null) {
        await _client
            .from('trip_seats')
            .update({'state': 'available', 'passenger_id': null})
            .eq('id', oldSeatId);
      }

      // 3. Occupy new seat
      final targetSeatState = passengerStatus == 'subscription'
          ? 'subscription'
          : 'reserved';
      await _client
          .from('trip_seats')
          .update({'state': targetSeatState, 'passenger_id': passengerId})
          .eq('id', newSeatId);

      // 4. Update passenger details
      await _client
          .from('trip_passengers')
          .update({'seat_id': newSeatId, 'seat_label': seatLabel})
          .eq('id', passengerId);

      await logEvent(
        tripId,
        'نقل مقعد راكب',
        'تم نقل الراكب $passengerName إلى المقعد الجديد رقم $seatLabel.',
      );

      return await fetchTripById(tripId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // Pricing Operations
  // ============================================================

  @override
  Future<List<TripPricingModel>> fetchTripPricing(String tripId) async {
    try {
      final response = await _client
          .from('trip_pricing')
          .select()
          .eq('trip_id', tripId)
          .order('from_point_order', ascending: true);

      return (response as List)
          .map(
            (json) => TripPricingModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing) async {
    try {
      final data = TripPricingModel.fromEntity(pricing).toJson();

      Map<String, dynamic> response;
      if (pricing.id.trim().isEmpty) {
        // Create new pricing segment
        data['trip_id'] = pricing.tripId;
        response = await _client
            .from('trip_pricing')
            .insert(data)
            .select()
            .single();
      } else {
        // Update existing pricing segment
        response = await _client
            .from('trip_pricing')
            .update(data)
            .eq('id', pricing.id)
            .select()
            .single();
      }

      await logEvent(
        pricing.tripId,
        'تحديث التسعير',
        'تم تحديث أو إضافة تسعير للقطاع: ${pricing.fromPointName} إلى ${pricing.toPointName}.',
      );

      return TripPricingModel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) async {
    try {
      final response = await _client
          .from('trip_pricing')
          .update({'is_active': isActive})
          .eq('id', pricingId)
          .select()
          .single();

      final pricing = TripPricingModel.fromJson(response);

      await logEvent(
        pricing.tripId,
        'تفعيل/تعطيل التسعير',
        'تم ${isActive ? "تفعيل" : "تعطيل"} تسعير قطاع السفر.',
      );

      return pricing;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // Events Log Helpers
  // ============================================================

  @override
  Future<List<TripEventModel>> fetchTripEvents(String tripId) async {
    try {
      final response = await _client
          .from('trip_events')
          .select()
          .eq('trip_id', tripId)
          .order('event_time', ascending: false);

      return (response as List)
          .map((json) => TripEventModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logEvent(String tripId, String title, String description) async {
    try {
      await _client.from('trip_events').insert({
        'trip_id': tripId,
        'title': title,
        'description': description,
        'event_time': DateTime.now().toUtc().toIso8601String(),
        'done': true,
      });
    } catch (e) {
      // Fail silently to prevent blocking core workflows
      developer.log('Supabase logEvent error: $e', error: e);
    }
  }

  /// Schedulable drivers, each carrying the vehicle they operate.
  ///
  /// One round trip, with the assignment and its vehicle embedded. The planner used to
  /// make two — the whole driver list and the whole vehicle list — and then let the
  /// operator combine them freely, which is the pairing bug this shape removes. Drivers
  /// with no assignment are still returned: the planner has to be able to show them and
  /// say *why* they cannot be scheduled, rather than hiding them and leaving the
  /// operator wondering where their driver went.
  @override
  Future<List<TripDriverOption>> fetchActiveDrivers() async {
    try {
      final response = await _client
          .from('drivers')
          .select('''
            id, full_name, phone,
            assignments(
              status,
              vehicles(id, plate_number, vehicle_code, vehicle_type, brand, model,
                       capacity, status)
            )
          ''')
          .eq('office_id', _session.officeId)
          .eq('status', 'active')
          .gte(
            'license_expiry_date',
            DateTime.now().toIso8601String().split('T').first,
          )
          .order('full_name');

      return (response as List)
          .map((json) => _driverOption(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// The one driver's pairing, for the pre-flight check on submit. Same shape as a row
  /// of [fetchActiveDrivers], re-read at submit time because the planner may have been
  /// open long enough for the fleet to have moved underneath it.
  @override
  Future<TripDriverOption?> fetchDriverAssignment(String driverId) async {
    try {
      final response = await _client
          .from('drivers')
          .select('''
            id, full_name, phone, status,
            assignments(
              status,
              vehicles(id, plate_number, vehicle_code, vehicle_type, brand, model,
                       capacity, status)
            )
          ''')
          .eq('id', driverId)
          .eq('office_id', _session.officeId)
          .maybeSingle();

      if (response == null) return null;
      return _driverOption(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// `assignments` is filtered in Dart rather than in the query: PostgREST's filter on
  /// an embedded table drops the *parent* row when nothing matches, which would silently
  /// hide every driver without a bus — exactly the drivers the planner needs to name.
  TripDriverOption _driverOption(Map<String, dynamic> json) {
    final assignments = (json['assignments'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    final active = assignments
        .where((a) => a['status'] == 'active' && a['vehicles'] != null)
        .firstOrNull;

    final vehicle = active?['vehicles'] as Map<String, dynamic>?;

    return TripDriverOption(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      assignedVehicle: vehicle == null
          ? null
          : AssignedVehicle(
              id: vehicle['id'] as String,
              plateNumber: vehicle['plate_number'] as String? ?? '',
              vehicleCode: vehicle['vehicle_code'] as String? ?? '',
              vehicleType: vehicle['vehicle_type'] as String? ?? '',
              brand: vehicle['brand'] as String? ?? '',
              model: vehicle['model'] as String? ?? '',
              capacity: vehicle['capacity'] as int? ?? 0,
              status: vehicle['status'] as String? ?? '',
            ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() async {
    try {
      final response = await _client
          .from('operation_routes')
          .select('*, route_stations(*)')
          .eq('office_id', _session.officeId)
          .eq('status', 'active');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) async {
    try {
      final start = DateTime.parse('$date $departureTime');
      var end = arrivalTime.isEmpty
          ? start.add(const Duration(hours: 1))
          : DateTime.parse('$date $arrivalTime');
      // Mirrors `service_window`'s generated formula: an arrival at or before
      // departure means the trip runs past midnight.
      if (arrivalTime.isNotEmpty && !end.isAfter(start)) {
        end = end.add(const Duration(days: 1));
      }
      end = end.add(const Duration(minutes: 30));

      final window = '[${_tsLiteral(start)},${_tsLiteral(end)})';
      final response = await _client
          .from('operation_trips')
          .select(
            'driver_id, vehicle_id, trip_code, trip_date, departure_time, arrival_time',
          )
          .eq('office_id', _session.officeId)
          .neq('status', 'cancelled')
          .overlaps('service_window', window);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _tsLiteral(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  @override
  Future<String> getRouteStatus(String routeId) async {
    try {
      final response = await _client
          .from('operation_routes')
          .select('status')
          .eq('id', routeId)
          .single();
      return response['status'] as String? ?? 'draft';
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // Realtime
  // ============================================================

  @override
  Stream<void> watchTripsChanges() {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _client
        .channel('dashboard_trip_management_${_session.officeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          callback: notify,
        );

    for (final table in const [
      'trip_seats',
      'trip_passengers',
      'trip_events',
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
  Stream<void> watchTripChanges(String tripId) {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    var channel = _client
        .channel('dashboard_trip_details_$tripId')
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
      'trip_seats',
      'trip_passengers',
      'trip_events',
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

  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      final translated = _translateServerError(error.message);
      if (translated != null) return Exception(translated);
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }

  /// Turns the lifecycle machine's error codes into something an operator can act on.
  ///
  /// These used to reach the screen as a raw Postgres message behind a fixed
  /// "تعذر تحديث حالة الرحلة." — so a refusal that had a specific, fixable cause
  /// (no pricing configured, say) read as an unexplained failure.
  String? _translateServerError(String message) {
    if (message.contains('trip_not_publishable:')) {
      final code = message
          .split('trip_not_publishable:')
          .last
          .split(RegExp(r'[^a-z_]'))[0];
      final blocker = TripPublishBlocker.fromCode(code);
      return 'تعذر فتح الحجز: ${blocker?.message ?? 'الرحلة غير جاهزة للنشر.'}';
    }
    if (message.contains('cancellation_reason_required')) {
      return 'يجب تحديد سبب الإلغاء لرحلة بدأ صعود ركابها أو انطلقت بالفعل.';
    }
    if (message.contains('trip_status_direct_update_forbidden') ||
        message.contains('trip_direct_write_forbidden')) {
      return 'لا يمكن تغيير حالة الرحلة بهذه الطريقة. استخدم الإجراء التشغيلي المتاح.';
    }
    if (message.contains('invalid_transition')) {
      return 'هذا الانتقال غير مسموح به في دورة حياة الرحلة.';
    }
    if (message.contains('trip_locked')) {
      return 'لا يمكن تعديل بيانات رحلة انطلقت أو انتهت بالفعل.';
    }
    if (message.contains('trip_delete_forbidden')) {
      return message.contains('has bookings')
          ? 'لا يمكن حذف رحلة عليها حجوزات — ألغِها بدلاً من ذلك.'
          : 'لا يمكن حذف رحلة تم نشرها — ألغِها بدلاً من ذلك.';
    }
    if (message.contains('trip_never_published')) {
      return 'لم يتم نشر هذه الرحلة أصلاً، فلا يمكن اعتبارها منفَّذة. ألغِها بدلاً من ذلك.';
    }
    if (message.contains('trip_already_closed')) {
      return 'تم إغلاق هذه الرحلة بالفعل.';
    }
    if (message.contains('not_authorized')) {
      return 'غير مصرح لك بتنفيذ هذا الإجراء على هذه الرحلة.';
    }
    if (message.contains('trip_not_found')) {
      return 'الرحلة غير موجودة.';
    }
    return null;
  }
}

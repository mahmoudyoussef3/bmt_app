import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../shared/data/models/operation_trip_model.dart';
import '../../../shared/data/models/trip_pricing_model.dart';

import 'trips_datasource.dart';

class SupabaseTripsDatasource implements TripsDatasource {
  final SupabaseClient _client;

  const SupabaseTripsDatasource(this._client);

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
        String arrivalOffset   = station['arrival_offset']?.toString()   ?? '';
        String departureOffset = station['departure_offset']?.toString() ?? '';

        if (input.customStationTimes.isNotEmpty) {
          final override = input.customStationTimes.firstWhere(
            (e) => e['route_point_id'] == stId,
            orElse: () => <String, String>{},
          );
          if (override.isNotEmpty) {
            final ca = override['arrival_offset'];
            final cd = override['departure_offset'];
            if (ca != null && ca.isNotEmpty) arrivalOffset   = ca;
            if (cd != null && cd.isNotEmpty) departureOffset = cd;
          }
        }

        routePoints.add({
          'route_point_id':   stId,
          'point_name':       station['name'],
          'point_order':      station['sort_order'],
          'arrival_offset':   arrivalOffset,
          'departure_offset': departureOffset,
          'latitude':         station['latitude'],
          'longitude':        station['longitude'],
        });
      }

      // 3. Build seats array from vehicle seat_configuration or default layout
      final vehicleResponse = await _client
          .from('vehicles')
          .select('seat_configuration')
          .eq('id', input.vehicleId)
          .single();

      final config = vehicleResponse['seat_configuration'] as Map<String, dynamic>?;
      final List<Map<String, dynamic>> seats = [];

      if (config != null && config['seats'] != null) {
        for (final seatVal in config['seats'] as List) {
          final s    = seatVal as Map<String, dynamic>;
          final type = s['seat_type'] as String? ?? 'passenger';
          if (type != 'passenger') continue;
          seats.add({
            'seat_label':  s['seat_number'] as String,
            'seat_row':    s['row']    as int? ?? 0,
            'seat_column': s['column'] as int? ?? 0,
          });
        }
      }

      if (seats.isEmpty) {
        const colCount = 3;
        var curRow  = 1;
        var seatNum = 1;
        while (seatNum <= input.capacity) {
          for (var col = 1; col <= colCount; col++) {
            if (seatNum > input.capacity) break;
            seats.add({
              'seat_label':  '$seatNum',
              'seat_row':    curRow,
              'seat_column': col,
            });
            seatNum++;
          }
          curRow++;
        }
      }

      // 4. Single atomic RPC call — all inserts in one transaction.
      //    If any insert fails the entire trip creation rolls back.
      final tripCode = 'TR-${DateTime.now().millisecondsSinceEpoch % 1000000}';

      final rpcResult = await _client.rpc('create_trip', params: {
        'p_trip_code':      tripCode,
        'p_route_id':       input.routeId,
        'p_driver_id':      input.driverId,
        'p_vehicle_id':     input.vehicleId,
        'p_trip_date':      input.date,
        'p_departure_time': input.departure,
        'p_arrival_time':   input.arrival,
        'p_capacity':       input.capacity,
        'p_ticket_price':   input.ticketPrice,
        'p_currency':       input.currency,
        'p_notes':          ['تم إنشاء الرحلة ونمذجة المحطات والمقاعد تلقائياً'],
        'p_route_points':   routePoints,
        'p_seats':          seats,
      });

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
      await _client
          .from('operation_trips')
          .update({
            'driver_id': trip.driverId,
            'vehicle_id': trip.vehicleId,
            'trip_date': trip.date,
            'departure_time': trip.departure,
            'arrival_time': trip.arrival.isEmpty ? null : trip.arrival,
            'status': trip.status.dbValue,
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
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) async {
    try {
      await _client
          .from('operation_trips')
          .update({'status': status.dbValue})
          .eq('id', tripId);

      await logEvent(
        tripId,
        'تحديث حالة الرحلة',
        'تم تغيير حالة الرحلة إلى: ${status.label}.',
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

  // Helper for driver and vehicle validation in wizard
  @override
  Future<List<Map<String, dynamic>>> fetchActiveDrivers() async {
    try {
      final response = await _client
          .from('drivers')
          .select('id, full_name, phone, status, license_expiry_date')
          .eq('status', 'active')
          .gte(
            'license_expiry_date',
            DateTime.now().toIso8601String().split('T').first,
          );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveVehicles() async {
    try {
      final response = await _client
          .from('vehicles')
          .select(
            'id, plate_number, vehicle_code, brand, model, capacity, vehicle_type, status, seat_configuration',
          )
          .eq('status', 'active');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() async {
    try {
      final response = await _client
          .from('operation_routes')
          .select('*, route_stations(*)')
          .eq('status', 'active');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> checkDuplicateTrip(
    String vehicleId,
    String date,
    String departureTime,
  ) async {
    try {
      final response = await _client
          .from('operation_trips')
          .select('id')
          .eq('vehicle_id', vehicleId)
          .eq('trip_date', date)
          .eq('departure_time', departureTime)
          .not('status', 'in', '(completed,cancelled)');
      return (response as List).isNotEmpty;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> checkDriverTripConflict(
    String driverId,
    String date,
    String departureTime,
  ) async {
    try {
      final response = await _client
          .from('operation_trips')
          .select('id')
          .eq('driver_id', driverId)
          .eq('trip_date', date)
          .eq('departure_time', departureTime)
          .not('status', 'in', '(completed,cancelled)');
      return (response as List).isNotEmpty;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<String> getDriverStatus(String driverId) async {
    try {
      final response = await _client
          .from('drivers')
          .select('status')
          .eq('id', driverId)
          .single();
      return response['status'] as String? ?? 'suspended';
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<String> getVehicleStatus(String vehicleId) async {
    try {
      final response = await _client
          .from('vehicles')
          .select('status')
          .eq('id', vehicleId)
          .single();
      return response['status'] as String? ?? 'suspended';
    } catch (e) {
      throw _handleError(e);
    }
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

  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }
}

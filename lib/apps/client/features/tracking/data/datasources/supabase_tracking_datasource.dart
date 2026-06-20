import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tracking_trip_model.dart';
import '../../domain/entities/tracking_trip.dart';

abstract class TrackingDatasource {
  Future<TrackingTripDataModel> getTrackingTrip({
    String? bookingId,
    String? tripId,
  });
}

class SupabaseTrackingDatasource implements TrackingDatasource {
  const SupabaseTrackingDatasource(this._client);

  final SupabaseClient _client;

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

    final results = await Future.wait([
      _client
          .from('trip_route_points')
          .select('latitude, longitude, point_name, point_order')
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
          .select('latitude, longitude, heading, speed, recorded_at')
          .eq('trip_id', resolvedTripId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    final pointRows = (results[0] as List?) ?? [];
    final tripRow = results[1] as Map<String, dynamic>?;
    final locRow = results[2] as Map<String, dynamic>?;

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
    final state = _mapTripState(tripStatus, hasLiveLocation: locRow != null);
    final departureAt = _combineDateAndTime(
      tripRow?['trip_date']?.toString(),
      tripRow?['departure_time']?.toString(),
    );
    final arrivalAt = _combineDateAndTime(
      tripRow?['trip_date']?.toString(),
      tripRow?['arrival_time']?.toString(),
    );
    final route = tripRow?['route'] as Map<String, dynamic>?;
    final driver = tripRow?['driver'] as Map<String, dynamic>?;
    final vehicle = tripRow?['vehicle'] as Map<String, dynamic>?;

    return TrackingTripDataModel(
      routePoints: routePoints,
      timelineSteps: _buildTimeline(state),
      stops: stops.isEmpty ? ['محطة البداية', 'محطة النهاية'] : stops,
      tripState: state,
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

  TrackingTripState _mapTripState(
    String tripStatus, {
    required bool hasLiveLocation,
  }) {
    return switch (tripStatus) {
      'open_for_booking' || 'scheduled' =>
        hasLiveLocation
            ? TrackingTripState.driverOnWay
            : TrackingTripState.notStarted,
      'in_progress' => TrackingTripState.inProgress,
      'boarding' => TrackingTripState.boarding,
      'completed' => TrackingTripState.completed,
      _ => TrackingTripState.notStarted,
    };
  }

  DateTime? _combineDateAndTime(String? date, String? time) {
    if (date == null || date.isEmpty || time == null || time.isEmpty) {
      return null;
    }
    return DateTime.tryParse('${date}T$time')?.toLocal();
  }

  List<String> _buildTimeline(TrackingTripState state) => const [
    'تأكيد الحجز',
    'السائق في الطريق',
    'صعود الركاب',
    'الرحلة انطلقت',
    'وصلنا',
  ];

  TrackingTripDataModel _emptyModel() => const TrackingTripDataModel(
    routePoints: [],
    timelineSteps: [
      'تأكيد الحجز',
      'السائق في الطريق',
      'صعود الركاب',
      'الرحلة انطلقت',
      'وصلنا',
    ],
    stops: [],
    tripState: TrackingTripState.notStarted,
  );
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tracking_trip_model.dart';
import '../../domain/entities/tracking_trip.dart';

abstract class TrackingDatasource {
  Future<TrackingTripDataModel> getTrackingTrip();
}

class SupabaseTrackingDatasource implements TrackingDatasource {
  const SupabaseTrackingDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<TrackingTripDataModel> getTrackingTrip() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _emptyModel();

    // Find the most recent active booking for this client.
    final booking = await _client
        .from('operation_bookings')
        .select('trip_id, status')
        .eq('client_id', userId)
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

    if (booking == null) return _emptyModel();
    final tripId = booking['trip_id'] as String?;
    if (tripId == null) return _emptyModel();

    final results = await Future.wait([
      _client
          .from('trip_route_points')
          .select('latitude, longitude, point_name, point_order')
          .eq('trip_id', tripId)
          .order('point_order'),
      _client
          .from('operation_trips')
          .select('status')
          .eq('id', tripId)
          .maybeSingle(),
      _client
          .from('trip_live_locations')
          .select('latitude, longitude')
          .eq('trip_id', tripId)
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
    final state = _mapTripState(booking['status'] as String, tripStatus);

    return TrackingTripDataModel(
      routePoints: routePoints,
      timelineSteps: _buildTimeline(state),
      stops: stops.isEmpty ? ['محطة البداية', 'محطة النهاية'] : stops,
      tripState: state,
      tripId: tripId,
      vehicleLatitude: locRow != null
          ? (locRow['latitude'] as num?)?.toDouble()
          : null,
      vehicleLongitude: locRow != null
          ? (locRow['longitude'] as num?)?.toDouble()
          : null,
    );
  }

  TrackingTripState _mapTripState(String bookingStatus, String tripStatus) {
    return switch (tripStatus) {
      'in_progress' => TrackingTripState.inProgress,
      'boarding' => TrackingTripState.boarding,
      'completed' => TrackingTripState.completed,
      _ => switch (bookingStatus) {
        'confirmed' => TrackingTripState.boarding,
        'approved' => TrackingTripState.driverOnWay,
        _ => TrackingTripState.notStarted,
      },
    };
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

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_live_map.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';
import 'package:bmt_app/core/maps/route_geometry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps widget tests offline: road geometry resolves to "unavailable"
/// synchronously, exercising the straight-line fallback path.
class _OfflineGeoService implements GeoService {
  @override
  bool get enabled => false;

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async =>
      const [];

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async =>
      throw const GeoException('offline');
}

void main() {
  setUp(() {
    RouteGeometryService.instance.debugGeoService = _OfflineGeoService();
  });
  tearDown(() {
    RouteGeometryService.instance.debugGeoService = null;
  });

  group('TrackingLiveMap', () {
    testWidgets('shows the shared empty panel when there is no map data', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackingLiveMap(
              routePoints: const [],
              vehicleFix: null,
              currentState: TrackingTripState.driverOnWay,
              onRefresh: () {},
            ),
          ),
        ),
      );

      expect(find.text('Map data unavailable'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });

    testWidgets('renders start/end station markers for a valid route', (
      tester,
    ) async {
      const routePoints = [
        TrackingPoint(latitude: 30.05, longitude: 31.20),
        TrackingPoint(latitude: 30.10, longitude: 31.25),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: TrackingLiveMap(
                routePoints: routePoints,
                vehicleFix: null,
                currentState: TrackingTripState.driverOnWay,
                onRefresh: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
      final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markers.markers, hasLength(2));
    });

    testWidgets('shows the captain card with driver identity when trip data is present', (
      tester,
    ) async {
      const routePoints = [
        TrackingPoint(latitude: 30.05, longitude: 31.20),
        TrackingPoint(latitude: 30.10, longitude: 31.25),
      ];
      const trip = TrackingTripData(
        routePoints: routePoints,
        timelineSteps: [],
        stops: [],
        tripState: TrackingTripState.driverOnWay,
        driverName: 'Ahmed Samir',
        vehiclePlate: 'ABC 123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: TrackingLiveMap(
                routePoints: routePoints,
                vehicleFix: null,
                currentState: TrackingTripState.driverOnWay,
                trip: trip,
                onRefresh: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ahmed Samir'), findsOneWidget);
      expect(find.text('ABC 123'), findsOneWidget);
    });
  });
}

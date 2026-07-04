import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_overview_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/google_style_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleStyleMapView', () {
    testWidgets('does not fabricate a marker when coordinates are missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GoogleStyleMapView())),
      );

      expect(find.text('Map coordinates unavailable'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });

    testWidgets('fits the camera to every mapped route station', (
      tester,
    ) async {
      const pins = [
        MapPinOption(label: 'First', subtitle: '', x: 30.05, y: 31.20),
        MapPinOption(label: 'Middle', subtitle: '', x: 30.25, y: 31.35),
        MapPinOption(label: 'Last', subtitle: '', x: 30.50, y: 31.55),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: GoogleStyleMapView(waypoints: pins),
            ),
          ),
        ),
      );

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(map.options.initialCameraFit, isNotNull);
      expect(markers.markers, hasLength(3));
      expect(find.text('3 mapped stations'), findsOneWidget);
    });
  });

  testWidgets('route overview orders endpoints by station order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const route = RouteOptionData(
      id: 'route-1',
      routeName: 'Cairo loop',
      pickup: 'Fallback pickup',
      destination: 'Fallback destination',
      distance: '24 km',
      duration: '40 min',
      availableSeats: 8,
      startingPrice: 'EGP 70',
      priceRange: 'EGP 70',
      availableTrips: [],
      points: [
        RoutePointData(name: 'Final station', order: 3),
        RoutePointData(name: 'First station', order: 1),
        RoutePointData(name: 'Middle station', order: 2),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: RouteOverviewScreen(route: route)),
    );

    expect(find.text('First station'), findsNWidgets(2));
    expect(find.text('Final station'), findsNWidgets(2));
    expect(find.text('Map coordinates unavailable'), findsOneWidget);
  });
}

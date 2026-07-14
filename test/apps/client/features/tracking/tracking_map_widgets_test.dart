import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/formatters/tracking_labels.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_map.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_signal_pill.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';
import 'package:bmt_app/core/maps/route_geometry_service.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

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

  group('TrackingMap', () {
    testWidgets('shows the localized empty panel when there is no map data', (
      tester,
    ) async {
      await _pump(
        tester,
        (labels) => TrackingMap(
          routePoints: const [],
          vehicleFix: null,
          progress: null,
          labels: labels,
          onRetry: () {},
        ),
      );

      expect(find.text('Map data unavailable'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });

    testWidgets('renders start/end markers for a valid route', (tester) async {
      await _pump(
        tester,
        (labels) => TrackingMap(
          routePoints: const [
            TrackingPoint(latitude: 30.05, longitude: 31.20),
            TrackingPoint(latitude: 30.10, longitude: 31.25),
          ],
          vehicleFix: null,
          progress: null,
          labels: labels,
          onRetry: () {},
        ),
      );
      await tester.pump();

      expect(find.byType(FlutterMap), findsOneWidget);
      final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markers.markers, hasLength(2));
    });
  });

  group('TrackingSignalPill', () {
    testWidgets('says it is waiting when the captain has sent nothing', (
      tester,
    ) async {
      await _pump(
        tester,
        (labels) => TrackingSignalPill(
          progress: _snapshot(hasVehicleFix: false),
          recordedAt: null,
          labels: labels,
        ),
      );

      expect(find.text("Waiting for the captain's signal"), findsOneWidget);
    });

    testWidgets('flags a stale fix rather than presenting it as live', (
      tester,
    ) async {
      await _pump(
        tester,
        (labels) => TrackingSignalPill(
          progress: _snapshot(hasVehicleFix: true, isStale: true),
          recordedAt: DateTime.now().subtract(const Duration(minutes: 4)),
          labels: labels,
        ),
      );

      expect(find.text('Signal delayed'), findsOneWidget);
      expect(find.text('4 min ago'), findsOneWidget);
      expect(find.text('Live'), findsNothing);
    });

    testWidgets('reads as live on a fresh fix', (tester) async {
      await _pump(
        tester,
        (labels) => TrackingSignalPill(
          progress: _snapshot(hasVehicleFix: true),
          recordedAt: DateTime.now(),
          labels: labels,
        ),
      );

      expect(find.text('Live'), findsOneWidget);
      expect(find.text('just now'), findsOneWidget);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget Function(TrackingLabels labels) build,
) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => SizedBox(
            width: 400,
            height: 500,
            child: build(
              TrackingLabels(
                AppLocalizations.of(context)!,
                Localizations.localeOf(context).toString(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

RouteProgressSnapshot _snapshot({
  required bool hasVehicleFix,
  bool isStale = false,
}) {
  return RouteProgressSnapshot(
    phase: TripProgressPhase.enRoute,
    hasVehicleFix: hasVehicleFix,
    isStale: isStale,
    isOffRoute: false,
    routeFraction: 0.2,
    traveledMeters: 200,
    totalRouteMeters: 1000,
    stops: const [],
    nextStopIndex: null,
  );
}

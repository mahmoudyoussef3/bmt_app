import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_map_overlays.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_stop_marker.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// A five-stop route: two done, the bus heading to the third, two ahead.
List<StopProgress> _stops() => [
  _stop('Ramses', 0, StopVisitStatus.departed),
  _stop('Dokki', 1, StopVisitStatus.departed),
  _stop('Giza', 2, StopVisitStatus.next),
  _stop('Haram', 3, StopVisitStatus.upcoming),
  _stop('October', 4, StopVisitStatus.upcoming),
];

StopProgress _stop(String name, int order, StopVisitStatus status) =>
    StopProgress(
      stop: RouteStop(
        name: name,
        latitude: 30.0 + order / 100,
        longitude: 31.0 + order / 100,
        order: order,
      ),
      status: status,
    );

TrackingStopMarker _markerAt(List<Marker> markers, int index) =>
    markers[index].child as TrackingStopMarker;

void main() {
  group('buildTrackingStopMarkers', () {
    test('drops intermediate stops when zoomed out past the declutter zoom', () {
      final markers = buildTrackingStopMarkers(
        route: const [],
        stops: _stops(),
        zoom: 11,
      );

      // Origin, the stop the bus is heading to, and the destination survive;
      // the two that carry no decision (Dokki, Haram) do not.
      expect(markers, hasLength(3));
      expect(_markerAt(markers, 1).status, StopVisitStatus.next);
      expect(_markerAt(markers, 2).isDestination, isTrue);
    });

    test('draws every stop once zoomed in', () {
      final markers = buildTrackingStopMarkers(
        route: const [],
        stops: _stops(),
        zoom: 14,
      );

      expect(markers, hasLength(5));
    });

    test('labels only the next stop and the destination', () {
      final markers = buildTrackingStopMarkers(
        route: const [],
        stops: _stops(),
        zoom: 14,
      );

      final labelled = markers
          .map((m) => m.child as TrackingStopMarker)
          .where((m) => m.name != null)
          .map((m) => m.name)
          .toList();

      expect(labelled, ['Giza', 'October']);
    });

    test('hides labels when they would be unreadable', () {
      final markers = buildTrackingStopMarkers(
        route: const [],
        stops: _stops(),
        zoom: 10,
      );

      expect(
        markers.every((m) => (m.child as TrackingStopMarker).name == null),
        isTrue,
      );
    });

    test('still marks where the trip starts and ends without progress data',
        () {
      final markers = buildTrackingStopMarkers(
        route: const [LatLng(30, 31), LatLng(30.1, 31.1)],
        stops: const [],
        zoom: 13,
      );

      expect(markers, hasLength(2));
      expect(_markerAt(markers, 1).isDestination, isTrue);
    });

    test('skips stops the dashboard saved without coordinates', () {
      final markers = buildTrackingStopMarkers(
        route: const [],
        stops: [
          _stop('Ramses', 0, StopVisitStatus.departed),
          StopProgress(
            stop: const RouteStop(
              name: 'Unmapped',
              latitude: 0,
              longitude: 0,
              order: 1,
            ),
            status: StopVisitStatus.next,
          ),
          _stop('Giza', 2, StopVisitStatus.upcoming),
        ],
        zoom: 14,
      );

      expect(markers, hasLength(2));
    });
  });
}

import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/markers/callout_marker.dart';
import 'package:bmt_app/core/widgets/maps/markers/pin_tail_painter.dart';
import 'package:bmt_app/core/widgets/maps/markers/station_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// flutter_map anchors a marker box *opposite* to its alignment, so the
/// intuitive-looking `Alignment.bottomCenter` hangs a pin a full box height
/// below its stop — pins then float off the route line (they read as
/// "unrelated points" next to the road). These tests pin the geometry down by
/// laying the markers out through flutter_map itself rather than by asserting
/// on the alignment constant alone.
void main() {
  const stop = LatLng(30.05, 31.20);
  const viewport = Size(400, 400);

  Future<void> pumpMap(
    WidgetTester tester,
    List<Marker> Function(BuildContext) markers,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: viewport.width,
              height: viewport.height,
              child: Builder(
                builder: (context) => FlutterMap(
                  options: const MapOptions(
                    initialCenter: stop,
                    initialZoom: 14,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [MarkerLayer(markers: markers(context))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The stop is the map's initial center, so it projects to the exact centre
  /// of the viewport.
  Offset stopOnScreen(WidgetTester tester) =>
      tester.getCenter(find.byType(FlutterMap));

  testWidgets('station pin rests its tail tip on the stop coordinate', (
    tester,
  ) async {
    await pumpMap(
      tester,
      (context) => [
        buildStationMarker(
          context,
          stop: const MapRouteStop(coordinate: stop, name: 'Ramses'),
          index: 1,
          count: 3,
          onTap: () {},
        ),
      ],
    );

    final tail = tester.getRect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is PinTailPainter,
      ),
    );
    final point = stopOnScreen(tester);

    expect(tail.bottom, moreOrLessEquals(point.dy, epsilon: 1));
    expect(tail.center.dx, moreOrLessEquals(point.dx, epsilon: 1));
  });

  testWidgets('callout floats above the pin instead of over the coordinate', (
    tester,
  ) async {
    await pumpMap(
      tester,
      (context) => [
        buildCalloutMarker(
          context,
          stop: const MapRouteStop(coordinate: stop, name: 'Ramses'),
          index: 1,
          count: 3,
        ),
      ],
    );

    final card = tester.getRect(find.text('Ramses'));
    final point = stopOnScreen(tester);

    // Entirely above the coordinate, and clear of the pin drawn there.
    expect(card.bottom, lessThan(point.dy - MapStyle.pinBox(false).height));
  });
}

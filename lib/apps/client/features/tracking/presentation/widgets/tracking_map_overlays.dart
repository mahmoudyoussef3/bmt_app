import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import 'tracking_stop_marker.dart';

/// Below this zoom the intermediate stops are closer together on screen than
/// the dots that mark them, so they collapse into a smear along the line.
/// Only the anchors of the journey (origin, next stop, destination) survive.
const _declutterZoom = 12.5;

/// Zoom at which stop names stop being readable and start being clutter.
const _labelZoom = 11.0;

/// Builds the live map's stop markers.
///
/// Every stop comes from the same visual family ([TrackingStopMarker]) whether
/// or not progress data has arrived — previously a trip without progress got
/// lettered A/B station pins and a trip with progress got dots, so the same
/// map looked like two different products depending on GPS.
List<Marker> buildTrackingStopMarkers({
  required List<LatLng> route,
  required List<StopProgress> stops,
  required double zoom,
}) {
  if (stops.isEmpty) return _routeEndMarkers(route);

  final markers = <Marker>[];
  for (final (i, stop) in stops.indexed) {
    if (!stop.stop.hasCoordinates) continue;

    final isDestination = i == stops.length - 1;
    // The stops that anchor the rider's mental picture of the trip: where it
    // began, where it ends, and where the bus is or is going. Everything else
    // — including stops already behind the bus — is detail that only earns
    // its pixels once you zoom in.
    final isAnchor = i == 0 ||
        isDestination ||
        stop.status == StopVisitStatus.next ||
        stop.status == StopVisitStatus.arrived;
    if (!isAnchor && zoom < _declutterZoom) continue;

    final named = zoom >= _labelZoom &&
        (isDestination || stop.status == StopVisitStatus.next);

    markers.add(
      Marker(
        point: LatLng(stop.stop.latitude, stop.stop.longitude),
        width: named ? 104 : 46,
        height: named ? 62 : 46,
        child: TrackingStopMarker(
          status: stop.status,
          isDestination: isDestination,
          name: named ? stop.stop.name : null,
        ),
      ),
    );
  }
  return markers;
}

/// Before the progress engine has anything to say, the route's own endpoints
/// still need to be legible: where this trip starts and where it ends.
List<Marker> _routeEndMarkers(List<LatLng> route) {
  if (route.isEmpty) return const [];
  return [
    Marker(
      point: route.first,
      width: 46,
      height: 46,
      child: const TrackingStopMarker(
        status: StopVisitStatus.departed,
        isDestination: false,
      ),
    ),
    if (route.length > 1)
      Marker(
        point: route.last,
        width: 46,
        height: 46,
        child: const TrackingStopMarker(
          status: StopVisitStatus.upcoming,
          isDestination: true,
        ),
      ),
  ];
}

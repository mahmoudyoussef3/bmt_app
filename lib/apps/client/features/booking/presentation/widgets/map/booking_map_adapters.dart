import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/maps/map_route_stop.dart';

/// Optional trip facts shown in the map's info overlay. Booking-specific
/// (seats/passengers are booking concepts) — every field is optional, and
/// missing values simply don't render. Distance/duration left null are
/// filled from road-geometry results when those are available.
class RouteMapInfoData {
  const RouteMapInfoData({
    this.distance,
    this.duration,
    this.status,
    this.availableSeats,
    this.passengerCount,
  });

  final String? distance;
  final String? duration;
  final String? status;
  final int? availableSeats;
  final int? passengerCount;
}

/// Converts raw booking pins into ordered, de-duplicated map stops, dropping
/// invalid coordinates so the UI never renders a marker for data that does
/// not exist.
List<MapRouteStop> routeMapStopsFromPins(List<MapPinOption> pins) {
  final points = <MapRouteStop>[];
  final seen = <String>{};

  for (final pin in pins) {
    final lat = pin.x;
    final lng = pin.y;
    final valid =
        lat.isFinite &&
        lng.isFinite &&
        !(lat == 0 && lng == 0) &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
    if (!valid) continue;
    final key = '${lat.toStringAsFixed(6)}:${lng.toStringAsFixed(6)}';
    if (!seen.add(key)) continue;
    points.add(
      MapRouteStop(coordinate: LatLng(lat, lng), name: pin.label.trim()),
    );
  }
  return points;
}

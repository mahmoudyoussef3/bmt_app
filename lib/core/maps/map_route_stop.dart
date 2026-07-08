import 'package:latlong2/latlong.dart';

/// A single mapped stop: its coordinate and (optional) display name.
///
/// Generic vocabulary shared by every map surface (Route Discovery, Route
/// Details, Live Tracking) — feature-specific screens adapt their own domain
/// entities (a booking pin, a trip route point, ...) into this shape rather
/// than the map widgets knowing about feature models.
class MapRouteStop {
  const MapRouteStop({required this.coordinate, this.name = ''});

  final LatLng coordinate;
  final String name;
}

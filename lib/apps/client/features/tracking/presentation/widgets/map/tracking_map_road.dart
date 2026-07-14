import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/route_geometry_cache.dart';
import 'package:bmt_app/core/maps/route_geometry_service.dart';

import '../../../domain/entities/tracking_point.dart';

/// The path the map actually draws.
///
/// Real road geometry when the routing service can give it (cached, so a trip
/// you have opened before draws roads on its very first frame), and the straight
/// stop-to-stop line until then — a bus that appears to drive through buildings
/// is worse than one drawn on a plain line while the roads load.
class TrackingMapRoad extends ChangeNotifier {
  List<LatLng> _stops = const [];
  RoadRoute? _road;

  /// The drawn path: roads if we have them, else the stop-to-stop fallback.
  List<LatLng> get points => _road?.points ?? _stops;

  bool get hasRoad => _road != null;

  /// Identifies the current stop set, so callers can tell a real route change
  /// from a rebuild that happens to carry the same stops.
  String get signature => RouteGeometryCache.signatureFor(_stops);

  /// Re-reads the stops and kicks off (or reuses) the road lookup. Notifies
  /// listeners only when geometry actually arrives.
  void sync(List<TrackingPoint> routePoints) {
    _stops = routePoints
        .where((p) => p.latitude != 0 && p.longitude != 0)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    _road = RouteGeometryService.instance.cached(_stops);
    if (_road == null && _stops.length > 1) _load(_stops);
  }

  Future<void> _load(List<LatLng> requested) async {
    final road = await RouteGeometryService.instance.load(requested);
    // The trip may have changed mid-flight; drop a stale response.
    if (!identical(requested, _stops)) return;
    _road = road;
    if (road != null) notifyListeners();
  }
}

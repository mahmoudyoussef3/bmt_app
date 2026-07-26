import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/route_geometry_cache.dart';
import 'package:bmt_app/core/maps/route_geometry_service.dart';

/// The path the captain map draws: real road geometry when the shared routing
/// service can resolve it (cached across screens, so a trip opened before draws
/// roads on its first frame), and the straight stop-to-stop line until then.
///
/// A mirror of the client's `TrackingMapRoad`, kept in the captain feature so
/// the two apps never import each other's presentation widgets — the heavy
/// lifting is the shared `RouteGeometryService` both call.
class CaptainMapRoad extends ChangeNotifier {
  List<LatLng> _stops = const [];
  RoadRoute? _road;

  List<LatLng> get points => _road?.points ?? _stops;

  bool get hasRoad => _road != null;

  String get signature => RouteGeometryCache.signatureFor(_stops);

  /// Re-reads the stops and kicks off (or reuses) the road lookup. Notifies
  /// listeners only when real geometry arrives.
  void sync(List<LatLng> stops) {
    _stops = stops
        .where((p) => p.latitude != 0 || p.longitude != 0)
        .toList(growable: false);

    _road = RouteGeometryService.instance.cached(_stops);
    if (_road == null && _stops.length > 1) _load(_stops);
  }

  Future<void> _load(List<LatLng> requested) async {
    final road = await RouteGeometryService.instance.load(requested);
    if (!identical(requested, _stops)) return; // Trip changed mid-flight.
    _road = road;
    if (road != null) notifyListeners();
  }
}

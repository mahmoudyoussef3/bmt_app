import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/search/place_search_text.dart';

import '../entities/operation_route.dart';
import '../entities/route_draft.dart';

/// One place the office already stops at, offered when a new stop is added.
///
/// EWT sells the same corridors over and over — Banha, Shibin El Qanater,
/// Mostorod, Ramses — so the same physical stop is typed again for every route
/// that passes through it. Retyping it is how a stop list ends up holding
/// "شبين القناطر", "شبين القناطر ", "Shibin El Qanater" and "شبين" as four
/// unrelated places, none of which a rider can match against another.
class RouteStopSuggestion {
  final String name;
  final String area;
  final String description;
  final GeoPoint? point;
  final RouteStopBoarding boarding;

  /// How many of the office's routes already stop here. Ranks the list so the
  /// stop an operator means is usually the first one offered.
  final int usageCount;

  const RouteStopSuggestion({
    required this.name,
    this.area = '',
    this.description = '',
    this.point,
    this.boarding = RouteStopBoarding.both,
    this.usageCount = 1,
  });

  bool get isLocated => point != null;

  /// Turns the suggestion into a stop, keeping the local [key] of the draft row
  /// it is filling so the widget tree and any in-flight reorder stay stable.
  /// The saved-row [RouteStopDraft.id] is deliberately *not* copied: reusing a
  /// place means "another stop at the same location", not "the same database
  /// row on two routes".
  RouteStopDraft toStop(String key) {
    return RouteStopDraft(
      key: key,
      name: name,
      area: area,
      description: description,
      point: point,
      boarding: boarding,
    );
  }
}

/// The office's own stops, searchable by name, area or address.
///
/// Built from routes already in memory — there is no extra query and no
/// cross-office read, so what an operator is offered is exactly what their own
/// routes have used before.
class RouteStopLibrary {
  final List<RouteStopSuggestion> stops;

  const RouteStopLibrary(this.stops);

  static const RouteStopLibrary empty = RouteStopLibrary([]);

  bool get isEmpty => stops.isEmpty;

  factory RouteStopLibrary.fromRoutes(Iterable<OperationRoute> routes) {
    final byKey = <String, RouteStopSuggestion>{};
    for (final route in routes) {
      for (final station in route.stations) {
        final name = station.name.trim();
        if (name.isEmpty) continue;
        final key = normalize(name);
        if (key.isEmpty) continue;
        final existing = byKey[key];
        final point = (station.latitude != null && station.longitude != null)
            ? GeoPoint(station.latitude!, station.longitude!)
            : null;
        if (existing == null) {
          byKey[key] = RouteStopSuggestion(
            name: name,
            area: station.area.trim(),
            description: station.locationDescription.trim(),
            point: point,
            boarding: RouteStopBoarding.fromFlags(
              pickupAllowed: station.pickupAllowed,
              dropoffAllowed: station.dropoffAllowed,
            ),
          );
          continue;
        }
        byKey[key] = RouteStopSuggestion(
          name: existing.name,
          area: existing.area.isEmpty ? station.area.trim() : existing.area,
          description: existing.description.isEmpty
              ? station.locationDescription.trim()
              : existing.description,
          point: existing.point ?? point,
          boarding: existing.boarding,
          usageCount: existing.usageCount + 1,
        );
      }
    }

    final result = byKey.values.toList()
      ..sort((a, b) {
        final byUsage = b.usageCount.compareTo(a.usageCount);
        return byUsage != 0 ? byUsage : a.name.compareTo(b.name);
      });
    return RouteStopLibrary(result);
  }

  /// Stops matching [query], most-used first. An empty query returns the
  /// most-used stops, which is what an operator opening the picker wants to see.
  List<RouteStopSuggestion> search(String query, {int limit = 8}) {
    final needle = normalize(query);
    if (needle.isEmpty) return stops.take(limit).toList();

    final starts = <RouteStopSuggestion>[];
    final contains = <RouteStopSuggestion>[];
    for (final stop in stops) {
      final haystacks = [
        normalize(stop.name),
        normalize(stop.area),
        normalize(stop.description),
      ];
      if (haystacks.any((value) => value.startsWith(needle))) {
        starts.add(stop);
      } else if (haystacks.any((value) => value.contains(needle))) {
        contains.add(stop);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  /// Folds away every difference that makes two spellings of one Egyptian place
  /// look like two places. Delegates to [PlaceSearchText.normalize], which the
  /// rider's route-catalog search folds by too — an operator's saved stop and a
  /// rider's typed one have to meet under the same rules.
  static String normalize(String value) => PlaceSearchText.normalize(value);
}

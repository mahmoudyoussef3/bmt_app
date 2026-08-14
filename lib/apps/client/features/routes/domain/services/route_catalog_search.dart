import 'package:bmt_app/core/search/place_search_text.dart';

import '../entities/route_search_match.dart';
import '../entities/route_summary.dart';

/// What the routes catalog's search box means.
///
/// A rider is not asking "which corridor is named this" — they are asking
/// "can I ride from/to here". So a query is matched against everything that
/// makes a route reachable: its name, its endpoints, the office running it,
/// and **every stop along the way**, not just the two ends.
///
/// The whole catalog is already in memory (a marketplace of a few dozen active
/// corridors), so this runs locally: a round trip per keystroke would only add
/// latency to a list the app is already holding.
abstract final class RouteCatalogSearch {
  /// [routes] narrowed to [query], each result carrying why it matched.
  ///
  /// An empty or whitespace-only query returns the full catalog, unlabelled.
  static List<RouteSearchMatch> apply(List<RouteSummary> routes, String query) {
    final needle = PlaceSearchText.normalize(query);
    if (needle.isEmpty) {
      return [for (final route in routes) RouteSearchMatch(route)];
    }

    final matches = <RouteSearchMatch>[];
    for (final route in routes) {
      if (_matchesIdentity(route, needle)) {
        matches.add(RouteSearchMatch(route));
        continue;
      }
      final caption = _stopCaption(route, needle);
      if (caption != null) {
        matches.add(RouteSearchMatch(route, viaStop: caption));
      }
    }
    return matches;
  }

  /// The facts a [RouteSummary] card already shows: label, endpoints, operator.
  /// A hit here needs no explanation on the card.
  static bool _matchesIdentity(RouteSummary route, String needle) {
    return PlaceSearchText.containsNormalized(route.name, needle) ||
        PlaceSearchText.containsNormalized(route.startCity, needle) ||
        PlaceSearchText.containsNormalized(route.endCity, needle) ||
        PlaceSearchText.containsNormalized(route.officeName, needle);
  }

  /// How a stop hit should be captioned: the name of the first *intermediate*
  /// stop matching [needle], `''` when only a terminal stop matched, and `null`
  /// when no stop matched at all and the route drops out of the results.
  ///
  /// A terminal stop is the origin or destination under another spelling —
  /// "محطة رمسيس" on a Cairo corridor — so it earns the route its place in the
  /// list but no "passing through" caption, which would misdescribe the trip.
  static String? _stopCaption(RouteSummary route, String needle) {
    final stops = route.stops;
    var terminalMatched = false;
    for (var i = 0; i < stops.length; i++) {
      final name = stops[i].name.trim();
      if (name.isEmpty) continue;
      if (!PlaceSearchText.containsNormalized(name, needle)) continue;
      if (i > 0 && i < stops.length - 1) return name;
      terminalMatched = true;
    }
    return terminalMatched ? '' : null;
  }
}

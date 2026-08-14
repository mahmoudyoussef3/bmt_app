import '../../domain/entities/route_search_match.dart';
import '../../domain/entities/route_summary.dart';
import '../../domain/services/route_catalog_search.dart';

sealed class RoutesDirectoryState {
  const RoutesDirectoryState();
}

class RoutesDirectoryLoading extends RoutesDirectoryState {
  const RoutesDirectoryLoading();
}

class RoutesDirectoryLoaded extends RoutesDirectoryState {
  RoutesDirectoryLoaded(this.routes, {this.query = ''});

  /// Every active route on the marketplace — the unfiltered catalog.
  final List<RouteSummary> routes;

  /// What the rider has typed into the catalog search.
  final String query;

  /// The routes actually listed, each with the reason it matched.
  ///
  /// Computed once per state rather than per read: the screen asks for the
  /// results three times in a build (the match count, the empty check, the
  /// list itself), and a keystroke rebuilds all three.
  late final List<RouteSearchMatch> visibleMatches = RouteCatalogSearch.apply(
    routes,
    query,
  );

  /// The same results without their match reasons, for callers that only need
  /// the corridors.
  List<RouteSummary> get visibleRoutes => [
    for (final match in visibleMatches) match.route,
  ];

  /// True when the catalog has routes but the query hides all of them —
  /// "nothing matched your search" is a different message from "no routes
  /// are running yet", and only one of the two is the rider's to fix.
  bool get isFilteredEmpty => routes.isNotEmpty && visibleMatches.isEmpty;

  RoutesDirectoryLoaded copyWith({List<RouteSummary>? routes, String? query}) {
    return RoutesDirectoryLoaded(
      routes ?? this.routes,
      query: query ?? this.query,
    );
  }
}

class RoutesDirectoryError extends RoutesDirectoryState {
  const RoutesDirectoryError(this.message);

  final String message;
}

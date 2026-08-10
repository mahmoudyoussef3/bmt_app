import '../../domain/entities/route_summary.dart';

sealed class RoutesDirectoryState {
  const RoutesDirectoryState();
}

class RoutesDirectoryLoading extends RoutesDirectoryState {
  const RoutesDirectoryLoading();
}

class RoutesDirectoryLoaded extends RoutesDirectoryState {
  const RoutesDirectoryLoaded(this.routes, {this.query = ''});

  /// Every active route on the marketplace — the unfiltered catalog.
  final List<RouteSummary> routes;

  /// What the rider has typed into the catalog search.
  final String query;

  /// The routes actually listed.
  ///
  /// Matches the route's name, either endpoint city, or the office running
  /// it — a rider browsing "all routes" is as likely to search a city or a
  /// company as the corridor's own label.
  List<RouteSummary> get visibleRoutes {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return routes;
    return routes.where((route) {
      if (route.name.toLowerCase().contains(needle)) return true;
      if (route.startCity.toLowerCase().contains(needle)) return true;
      if (route.endCity.toLowerCase().contains(needle)) return true;
      return route.officeName.toLowerCase().contains(needle);
    }).toList();
  }

  /// True when the catalog has routes but the query hides all of them —
  /// "nothing matched your search" is a different message from "no routes
  /// are running yet", and only one of the two is the rider's to fix.
  bool get isFilteredEmpty => routes.isNotEmpty && visibleRoutes.isEmpty;

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

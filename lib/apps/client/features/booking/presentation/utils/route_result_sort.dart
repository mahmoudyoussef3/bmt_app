/// Sort order for the routes discovery/results grid.
enum RouteResultSort { recommended, priceLow, durationShort, tripsHigh }

String routeResultSortLabel(RouteResultSort sort) {
  return switch (sort) {
    RouteResultSort.recommended => 'Recommended',
    RouteResultSort.priceLow => 'Lowest price',
    RouteResultSort.durationShort => 'Shortest duration',
    RouteResultSort.tripsHigh => 'Most trips',
  };
}

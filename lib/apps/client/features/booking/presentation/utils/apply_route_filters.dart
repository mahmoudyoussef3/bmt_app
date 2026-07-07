import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';

/// Applies free-text search plus [criteria]'s filter/sort to [routes].
List<PopularRouteListData> applyRouteFilters(
  List<PopularRouteListData> routes,
  RouteFilterCriteria criteria,
  String query,
) {
  final trimmed = query.trim().toLowerCase();
  final filtered = routes.where((route) {
    final matchesQuery =
        trimmed.isEmpty ||
        route.routeName.toLowerCase().contains(trimmed) ||
        route.pickup.toLowerCase().contains(trimmed) ||
        route.destination.toLowerCase().contains(trimmed);
    return matchesQuery && criteria.matches(route);
  }).toList();

  filtered.sort(criteria.compare);
  return filtered;
}

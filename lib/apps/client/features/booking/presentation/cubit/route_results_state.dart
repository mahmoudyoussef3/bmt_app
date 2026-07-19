import '../../domain/entities/booking_option.dart';

sealed class RouteResultsState {
  const RouteResultsState();
}

class RouteResultsLoading extends RouteResultsState {
  const RouteResultsLoading();
}

class RouteResultsLoaded extends RouteResultsState {
  const RouteResultsLoaded({
    required this.routes,
    this.selectedRouteId,
    this.selectedTripId,
  });

  final List<RouteOptionData> routes;
  final String? selectedRouteId;
  final String? selectedTripId;

  /// The route matching [selectedRouteId], falling back to the first result.
  RouteOptionData? get selectedRoute {
    if (routes.isEmpty) return null;
    return routes.firstWhere(
      (route) => route.id == selectedRouteId,
      orElse: () => routes.first,
    );
  }

  RouteResultsLoaded copyWith({
    List<RouteOptionData>? routes,
    String? selectedRouteId,
    String? selectedTripId,
    bool clearSelectedTrip = false,
  }) {
    return RouteResultsLoaded(
      routes: routes ?? this.routes,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      selectedTripId: clearSelectedTrip
          ? null
          : selectedTripId ?? this.selectedTripId,
    );
  }
}

class RouteResultsError extends RouteResultsState {
  const RouteResultsError(this.message);

  final String message;
}

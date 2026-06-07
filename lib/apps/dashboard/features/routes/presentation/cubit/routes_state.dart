import '../../domain/entities/operation_route.dart';

enum RoutesView { operations, builder }

sealed class RoutesState {
  const RoutesState();
}

class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

class RoutesError extends RoutesState {
  final String message;

  const RoutesError(this.message);
}

class RoutesLoaded extends RoutesState {
  final List<OperationRoute> routes;
  final String selectedRouteId;
  final RoutesView view;

  const RoutesLoaded({
    required this.routes,
    required this.selectedRouteId,
    this.view = RoutesView.operations,
  });

  OperationRoute get selectedRoute {
    return routes.firstWhere(
      (route) => route.id == selectedRouteId,
      orElse: () => routes.first,
    );
  }

  RoutesLoaded copyWith({
    List<OperationRoute>? routes,
    String? selectedRouteId,
    RoutesView? view,
  }) {
    return RoutesLoaded(
      routes: routes ?? this.routes,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      view: view ?? this.view,
    );
  }
}

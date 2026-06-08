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
  final OperationRoute? editingRoute;

  const RoutesLoaded({
    required this.routes,
    required this.selectedRouteId,
    this.view = RoutesView.operations,
    this.editingRoute,
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
    OperationRoute? editingRoute,
    bool clearEditingRoute = false,
  }) {
    return RoutesLoaded(
      routes: routes ?? this.routes,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      view: view ?? this.view,
      editingRoute: clearEditingRoute
          ? null
          : editingRoute ?? this.editingRoute,
    );
  }
}

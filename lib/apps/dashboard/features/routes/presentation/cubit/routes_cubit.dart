import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_route.dart';
import '../../domain/usecases/add_route_station_usecase.dart';
import '../../domain/usecases/create_route_usecase.dart';
import '../../domain/usecases/delete_route_station_usecase.dart';
import '../../domain/usecases/get_operation_routes_usecase.dart';
import '../../domain/usecases/reorder_route_stations_usecase.dart';
import '../../domain/usecases/update_route_station_usecase.dart';
import '../../domain/usecases/update_route_usecase.dart';
import 'routes_state.dart';

class RoutesCubit extends Cubit<RoutesState> {
  final GetOperationRoutesUseCase _getRoutes;
  final CreateRouteUseCase _createRoute;
  final UpdateRouteUseCase _updateRoute;
  final AddRouteStationUseCase _addStation;
  final UpdateRouteStationUseCase _updateStation;
  final DeleteRouteStationUseCase _deleteStation;
  final ReorderRouteStationsUseCase _reorderStations;

  RoutesCubit({
    required GetOperationRoutesUseCase getRoutes,
    required CreateRouteUseCase createRoute,
    required UpdateRouteUseCase updateRoute,
    required AddRouteStationUseCase addStation,
    required UpdateRouteStationUseCase updateStation,
    required DeleteRouteStationUseCase deleteStation,
    required ReorderRouteStationsUseCase reorderStations,
  }) : _getRoutes = getRoutes,
       _createRoute = createRoute,
       _updateRoute = updateRoute,
       _addStation = addStation,
       _updateStation = updateStation,
       _deleteStation = deleteStation,
       _reorderStations = reorderStations,
       super(const RoutesLoading());

  Future<void> load() async {
    emit(const RoutesLoading());
    try {
      final routes = await _getRoutes();
      emit(RoutesLoaded(routes: routes, selectedRouteId: routes.first.id));
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  void selectRoute(String routeId) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(
      current.copyWith(selectedRouteId: routeId, view: RoutesView.operations),
    );
  }

  void showBuilder() {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(view: RoutesView.builder, clearEditingRoute: true));
  }

  void showEditRoute(OperationRoute route) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(view: RoutesView.builder, editingRoute: route));
  }

  void showOperations() {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(
      current.copyWith(view: RoutesView.operations, clearEditingRoute: true),
    );
  }

  Future<void> createRoute(OperationRoute route) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final created = await _createRoute(route);
      emit(
        current.copyWith(
          routes: [created, ...current.routes],
          selectedRouteId: created.id,
          view: RoutesView.operations,
        ),
      );
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> updateRoute(OperationRoute route) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final updated = await _updateRoute(route);
      _emitUpdatedRoute(current, updated);
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> saveRoute(OperationRoute route) async {
    if (route.id.isEmpty) {
      await createRoute(route);
    } else {
      await updateRoute(route);
    }
  }

  Future<void> duplicateRoute(OperationRoute route) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final created = await _createRoute(
        route.copyWith(
          id: '',
          name: '${route.name} - نسخة',
          status: OperationRouteStatus.draft,
          tripsCount: 0,
          stations: route.stations
              .map((station) => station.copyWith(id: ''))
              .toList(),
          notes: [...route.notes, 'تم إنشاء نسخة من ${route.name}.'],
        ),
      );
      emit(
        current.copyWith(
          routes: [created, ...current.routes],
          selectedRouteId: created.id,
          view: RoutesView.operations,
          clearEditingRoute: true,
        ),
      );
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> archiveRoute(OperationRoute route) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final updated = await _updateRoute(
        route.copyWith(status: OperationRouteStatus.archived),
      );
      _emitUpdatedRoute(current, updated);
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> addStation(RouteStation station) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final updated = await _addStation(current.selectedRoute.id, station);
      _emitUpdatedRoute(current, updated);
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> updateStation(RouteStation station) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final updated = await _updateStation(current.selectedRoute.id, station);
      _emitUpdatedRoute(current, updated);
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> deleteStation(RouteStation station) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      await _deleteStation(current.selectedRoute.id, station.id);
      final routes = await _getRoutes();
      emit(current.copyWith(routes: routes));
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  Future<void> reorderStations(int oldIndex, int newIndex) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    try {
      final updated = await _reorderStations(
        current.selectedRoute.id,
        oldIndex,
        newIndex,
      );
      _emitUpdatedRoute(current, updated);
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  void _emitUpdatedRoute(RoutesLoaded current, OperationRoute updated) {
    final routes = current.routes
        .map((route) => route.id == updated.id ? updated : route)
        .toList();
    emit(current.copyWith(routes: routes, selectedRouteId: updated.id));
  }
}

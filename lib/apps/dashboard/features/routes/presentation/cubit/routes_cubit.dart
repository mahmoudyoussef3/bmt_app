import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_route.dart';
import '../../domain/usecases/add_route_station_usecase.dart';
import '../../domain/usecases/create_route_usecase.dart';
import '../../domain/usecases/delete_route_usecase.dart';
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
  final DeleteRouteUseCase _deleteRoute;
  final AddRouteStationUseCase _addStation;
  final UpdateRouteStationUseCase _updateStation;
  final DeleteRouteStationUseCase _deleteStation;
  final ReorderRouteStationsUseCase _reorderStations;

  RoutesCubit({
    required GetOperationRoutesUseCase getRoutes,
    required CreateRouteUseCase createRoute,
    required UpdateRouteUseCase updateRoute,
    required DeleteRouteUseCase deleteRoute,
    required AddRouteStationUseCase addStation,
    required UpdateRouteStationUseCase updateStation,
    required DeleteRouteStationUseCase deleteStation,
    required ReorderRouteStationsUseCase reorderStations,
  }) : _getRoutes = getRoutes,
       _createRoute = createRoute,
       _updateRoute = updateRoute,
       _deleteRoute = deleteRoute,
       _addStation = addStation,
       _updateStation = updateStation,
       _deleteStation = deleteStation,
       _reorderStations = reorderStations,
       super(const RoutesLoading());

  Future<void> load() async {
    emit(const RoutesLoading());
    try {
      final routes = await _getRoutes();
      final selectedRouteId = routes.isNotEmpty ? routes.first.id : '';
      emit(RoutesLoaded(routes: routes, selectedRouteId: selectedRouteId));
    } catch (error) {
      emit(RoutesError(error.toString()));
    }
  }

  void selectRoute(String routeId) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(selectedRouteId: routeId, view: RoutesView.details));
  }

  void showBuilder() {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(view: RoutesView.form, clearEditingRoute: true));
  }

  void showEditRoute(OperationRoute route) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(view: RoutesView.form, editingRoute: route));
  }

  void showOperations() {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(view: RoutesView.list, clearEditingRoute: true));
  }

  void showDetails(OperationRoute route) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(
      current.copyWith(
        selectedRouteId: route.id,
        view: RoutesView.details,
        clearEditingRoute: true,
      ),
    );
  }

  void updateSearch(String query) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(searchQuery: query, view: RoutesView.list));
  }

  void updateStatusFilter(OperationRouteStatus? status) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(
      current.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        view: RoutesView.list,
      ),
    );
  }

  void updateCityFilter(String city) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(cityFilter: city, view: RoutesView.list));
  }

  void updateStopsFilter(StopsCountFilter filter) {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(stopsFilter: filter, view: RoutesView.list));
  }

  /// Creates or updates the route the builder produced.
  ///
  /// Success lands on the route's detail page with a confirmation; failure
  /// keeps the builder on screen and reports the reason next to the save
  /// button. A rejected save used to emit [RoutesError], which replaced the
  /// whole module with an error page and discarded the draft.
  Future<void> saveRoute(OperationRoute route) async {
    final current = state;
    if (current is! RoutesLoaded || current.saving) return;
    emit(current.copyWith(saving: true));
    final creating = route.id.isEmpty;
    try {
      final saved = creating
          ? await _createRoute(route)
          : await _updateRoute(route);
      final routes = creating
          ? [saved, ...current.routes]
          : current.routes
                .map((item) => item.id == saved.id ? saved : item)
                .toList();
      emit(
        current.copyWith(
          routes: routes,
          selectedRouteId: saved.id,
          view: RoutesView.details,
          clearEditingRoute: true,
          saving: false,
          flashMessage: creating
              ? 'تم إنشاء مسار "${saved.name}"'
              : 'تم حفظ تعديلات "${saved.name}"',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          saving: false,
          view: RoutesView.form,
          editingRoute: current.editingRoute,
          actionError: _friendlyError(error.toString()),
        ),
      );
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
          view: RoutesView.details,
          clearEditingRoute: true,
          flashMessage: 'تم نسخ المسار',
        ),
      );
    } catch (error) {
      emit(current.copyWith(actionError: _friendlyError(error.toString())));
    }
  }

  Future<void> archiveRoute(OperationRoute route) async {
    await _mutate(
      () => _updateRoute(route.copyWith(status: OperationRouteStatus.archived)),
      view: RoutesView.list,
      flashMessage: 'تمت أرشفة "${route.name}"',
    );
  }

  Future<void> pauseRoute(OperationRoute route) async {
    await _mutate(
      () => _updateRoute(route.copyWith(status: OperationRouteStatus.paused)),
      view: RoutesView.list,
      flashMessage: 'تم إيقاف "${route.name}" مؤقتاً',
    );
  }

  Future<void> deleteRoute(OperationRoute route) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    emit(current.copyWith(saving: true));
    try {
      await _deleteRoute(route.id);
      final routes = current.routes
          .where((candidate) => candidate.id != route.id)
          .toList();
      emit(
        current.copyWith(
          routes: routes,
          selectedRouteId: routes.isNotEmpty ? routes.first.id : '',
          view: RoutesView.list,
          clearEditingRoute: true,
          saving: false,
          flashMessage: 'تم حذف "${route.name}"',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          saving: false,
          actionError: _friendlyError(error.toString()),
        ),
      );
    }
  }

  Future<void> addStation(RouteStation station) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    await _mutate(
      () => _addStation(current.selectedRoute.id, station),
      flashMessage: 'تمت إضافة المحطة',
    );
  }

  Future<void> updateStation(RouteStation station) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    await _mutate(
      () => _updateStation(current.selectedRoute.id, station),
      flashMessage: 'تم تحديث المحطة',
    );
  }

  Future<void> deleteStation(RouteStation station) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    await _mutate(
      () async {
        await _deleteStation(current.selectedRoute.id, station.id);
        final routes = await _getRoutes();
        return routes.firstWhere(
          (route) => route.id == current.selectedRoute.id,
          orElse: () => current.selectedRoute,
        );
      },
      flashMessage: 'تم حذف المحطة',
    );
  }

  Future<void> reorderStations(int oldIndex, int newIndex) async {
    final current = state;
    if (current is! RoutesLoaded) return;
    await _mutate(
      () => _reorderStations(current.selectedRoute.id, oldIndex, newIndex),
    );
  }

  /// Runs a write that returns the updated route, swapping it into the list.
  /// Failure surfaces beside the data instead of replacing it.
  Future<void> _mutate(
    Future<OperationRoute> Function() action, {
    RoutesView? view,
    String flashMessage = '',
  }) async {
    final current = state;
    if (current is! RoutesLoaded || current.saving) return;
    emit(current.copyWith(saving: true));
    try {
      final updated = await action();
      emit(
        current.copyWith(
          routes: current.routes
              .map((route) => route.id == updated.id ? updated : route)
              .toList(),
          selectedRouteId: updated.id,
          view: view,
          saving: false,
          flashMessage: flashMessage,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          saving: false,
          actionError: _friendlyError(error.toString()),
        ),
      );
    }
  }

  /// Turns a database rejection into something the operator can act on.
  static String _friendlyError(String raw) {
    if (raw.contains('duplicate key') && raw.contains('route_code')) {
      return 'كود المسار مستخدم بالفعل في مكتبك. غيّر الكود ثم احفظ مرة أخرى.';
    }
    if (raw.contains('violates foreign key') && raw.contains('route')) {
      return 'لا يمكن حذف هذا المسار لارتباطه برحلات محفوظة. أرشفه بدلاً من حذفه.';
    }
    if (raw.contains('row-level security') || raw.contains('permission denied')) {
      return 'ليس لديك صلاحية تعديل مسارات هذا المكتب.';
    }
    return raw.replaceFirst('Exception: ', '');
  }
}

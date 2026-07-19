import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_search_query.dart';
import '../../domain/usecases/get_booking_routes_usecase.dart';
import 'route_results_state.dart';

/// Loads the bookable routes for a [BookingSearchQuery] and tracks which route
/// and trip the rider has selected.
class RouteResultsCubit extends Cubit<RouteResultsState> {
  RouteResultsCubit(this._getRoutes) : super(const RouteResultsLoading());

  final GetBookingRoutesUseCase _getRoutes;
  bool _inFlight = false;

  Future<void> load(BookingSearchQuery query) async {
    if (_inFlight) return;
    _inFlight = true;
    emit(const RouteResultsLoading());
    try {
      final routes = await _getRoutes(query);
      emit(
        RouteResultsLoaded(
          routes: routes,
          selectedRouteId: _defaultSelectedId(routes, query.routeId),
        ),
      );
    } catch (error) {
      emit(RouteResultsError(error.toString()));
    } finally {
      _inFlight = false;
    }
  }

  void selectRoute(String id) {
    final current = state;
    if (current is! RouteResultsLoaded) return;
    emit(current.copyWith(selectedRouteId: id, clearSelectedTrip: true));
  }

  void selectTrip(String id) {
    final current = state;
    if (current is! RouteResultsLoaded) return;
    emit(current.copyWith(selectedTripId: id));
  }

  String? _defaultSelectedId(
    List<RouteOptionData> routes,
    String? queryRouteId,
  ) {
    if (routes.isEmpty) return null;
    if (queryRouteId != null &&
        routes.any((route) => route.id == queryRouteId)) {
      return queryRouteId;
    }
    return routes.first.id;
  }
}

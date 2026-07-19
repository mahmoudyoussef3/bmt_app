import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_popular_routes_usecase.dart';
import 'popular_routes_state.dart';

/// Loads the most-booked routes for the popular-routes discovery screen.
class PopularRoutesCubit extends Cubit<PopularRoutesState> {
  PopularRoutesCubit(this._getPopularRoutes)
    : super(const PopularRoutesLoading());

  final GetPopularRoutesUseCase _getPopularRoutes;
  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    emit(const PopularRoutesLoading());
    try {
      emit(PopularRoutesLoaded(await _getPopularRoutes()));
    } catch (error) {
      emit(PopularRoutesError(error.toString()));
    } finally {
      _inFlight = false;
    }
  }
}

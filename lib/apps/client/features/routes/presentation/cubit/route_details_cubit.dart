import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_route_details_usecase.dart';
import 'route_details_state.dart';

class RouteDetailsCubit extends Cubit<RouteDetailsState> {
  RouteDetailsCubit(this._getRouteDetails)
    : super(const RouteDetailsLoading());

  final GetRouteDetailsUseCase _getRouteDetails;

  Future<void> load(String routeId) async {
    emit(const RouteDetailsLoading());
    try {
      final details = await _getRouteDetails(routeId);
      if (isClosed) return;
      emit(RouteDetailsLoaded(details));
    } catch (e) {
      if (isClosed) return;
      emit(RouteDetailsError(e.toString()));
    }
  }
}

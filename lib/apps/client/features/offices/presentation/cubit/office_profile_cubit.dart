import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_office_routes_usecase.dart';
import '../../domain/usecases/get_office_trips_usecase.dart';
import 'office_profile_state.dart';

class OfficeProfileCubit extends Cubit<OfficeProfileState> {
  OfficeProfileCubit(this._getOfficeRoutes, this._getOfficeTrips)
    : super(const OfficeProfileLoading());

  final GetOfficeRoutesUseCase _getOfficeRoutes;
  final GetOfficeTripsUseCase _getOfficeTrips;

  /// Routes and departures are fetched together: the profile shows both at
  /// once, and sequential round-trips would hold the whole screen in its
  /// skeleton for longer.
  Future<void> load(String officeId) async {
    emit(const OfficeProfileLoading());
    try {
      final routes = _getOfficeRoutes(officeId);
      final trips = _getOfficeTrips(officeId);
      final loaded = OfficeProfileLoaded(
        routes: await routes,
        trips: await trips,
      );
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      emit(OfficeProfileError(e.toString()));
    }
  }
}

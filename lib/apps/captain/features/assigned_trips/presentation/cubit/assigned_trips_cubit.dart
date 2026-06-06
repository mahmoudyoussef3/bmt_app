import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_assigned_trips_usecase.dart';
import 'assigned_trips_state.dart';

class AssignedTripsCubit extends Cubit<AssignedTripsState> {
  AssignedTripsCubit(this._getAssignedTrips)
    : super(const AssignedTripsLoading());

  final GetAssignedTripsUseCase _getAssignedTrips;

  Future<void> load() async {
    emit(const AssignedTripsLoading());
    try {
      final trips = await _getAssignedTrips();
      emit(AssignedTripsLoaded(trips));
    } catch (error) {
      emit(AssignedTripsError(error.toString()));
    }
  }
}

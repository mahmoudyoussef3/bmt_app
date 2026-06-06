import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_trip_status.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import 'trip_status_update_state.dart';

class TripStatusUpdateCubit extends Cubit<TripStatusUpdateState> {
  TripStatusUpdateCubit(this._updateStatus)
    : super(const TripStatusUpdateReady());

  final UpdateTripStatusUseCase _updateStatus;

  Future<void> update(String tripId, CaptainTripStatus status) async {
    emit(const TripStatusUpdateLoading());
    try {
      final update = await _updateStatus(tripId, status);
      emit(TripStatusUpdateReady(status: update.status));
    } catch (error) {
      emit(TripStatusUpdateError(error.toString()));
    }
  }
}

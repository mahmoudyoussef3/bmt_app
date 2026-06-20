import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_trip_status.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import 'trip_status_update_state.dart';

class TripStatusUpdateCubit extends Cubit<TripStatusUpdateState> {
  TripStatusUpdateCubit(this._updateStatus)
    : super(const TripStatusUpdateReady());

  final UpdateTripStatusUseCase _updateStatus;
  CaptainTripStatus? _status;

  Future<void> update(String tripId, CaptainTripStatus status) async {
    _status = status;
    emit(TripStatusUpdateLoading(status: status));
    try {
      final update = await _updateStatus(tripId, status);
      _status = update.status;
      emit(TripStatusUpdateReady(status: update.status));
    } catch (error) {
      emit(TripStatusUpdateError(error.toString(), status: _status));
    }
  }
}

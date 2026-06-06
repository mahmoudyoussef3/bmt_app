import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/start_location_sharing_usecase.dart';
import '../../domain/usecases/stop_location_sharing_usecase.dart';
import 'live_location_state.dart';

class LiveLocationCubit extends Cubit<LiveLocationState> {
  LiveLocationCubit({
    required StartLocationSharingUseCase startSharing,
    required StopLocationSharingUseCase stopSharing,
  }) : _startSharing = startSharing,
       _stopSharing = stopSharing,
       super(const LiveLocationReady());

  final StartLocationSharingUseCase _startSharing;
  final StopLocationSharingUseCase _stopSharing;

  Future<void> start(String tripId) async {
    emit(const LiveLocationLoading());
    try {
      emit(LiveLocationReady(enabled: (await _startSharing(tripId)).enabled));
    } catch (error) {
      emit(LiveLocationError(error.toString()));
    }
  }

  Future<void> stop(String tripId) async {
    emit(const LiveLocationLoading());
    try {
      emit(LiveLocationReady(enabled: (await _stopSharing(tripId)).enabled));
    } catch (error) {
      emit(LiveLocationError(error.toString()));
    }
  }
}

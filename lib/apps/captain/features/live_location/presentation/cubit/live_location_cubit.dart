import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/send_location_update_usecase.dart';
import 'live_location_state.dart';

class LiveLocationCubit extends Cubit<LiveLocationState> {
  LiveLocationCubit({required SendLocationUpdateUseCase sendLocation})
    : _sendLocation = sendLocation,
      super(const LiveLocationReady());

  final SendLocationUpdateUseCase _sendLocation;

  Future<void> send(String tripId) async {
    emit(const LiveLocationLoading());
    try {
      final update = await _sendLocation(tripId);
      emit(LiveLocationReady(lastSentAt: update.recordedAt));
    } catch (error) {
      emit(
        LiveLocationError(
          error.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
        ),
      );
    }
  }
}

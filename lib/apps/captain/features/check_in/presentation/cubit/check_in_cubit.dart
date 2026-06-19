import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../../domain/usecases/check_passenger_usecase.dart';
import 'check_in_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit(this._checkPassenger, this._repository)
    : super(const CheckInReady());

  final CheckPassengerUseCase _checkPassenger;
  final CheckInRepository _repository;

  Future<void> loadQueueCount() async {
    final count = await _repository.offlineQueueLength;
    final current = state;
    if (current is CheckInReady) {
      emit(CheckInReady(result: current.result, offlineQueueCount: count));
    }
  }

  Future<void> flushOfflineQueue() async {
    final flushed = await _repository.flushOfflineQueue();
    if (flushed > 0) {
      final count = await _repository.offlineQueueLength;
      final current = state;
      if (current is CheckInReady) {
        emit(CheckInReady(result: current.result, offlineQueueCount: count));
      }
    }
  }

  Future<void> check({
    required String tripId,
    required String bookingId,
    required CheckInStatus status,
  }) async {
    emit(const CheckInLoading());
    try {
      final result = await _checkPassenger(
        tripId: tripId,
        bookingId: bookingId,
        status: status,
      );
      final count = await _repository.offlineQueueLength;
      emit(CheckInReady(result: result, offlineQueueCount: count));
    } catch (error) {
      emit(CheckInError(error.toString()));
    }
  }
}

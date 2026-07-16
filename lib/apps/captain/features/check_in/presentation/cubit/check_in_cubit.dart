import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../../domain/usecases/check_passenger_usecase.dart';
import 'check_in_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit(this._checkPassenger, this._repository)
    : super(const CheckInReady()) {
    // Flush queued offline check-ins the moment connectivity comes back,
    // rather than only when the captain happens to reopen this screen or tap
    // "flush" manually — a check-in scanned offline could otherwise sit
    // unsynced for the rest of the trip.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!_isOffline(results)) flushOfflineQueue();
    });
  }

  final CheckPassengerUseCase _checkPassenger;
  final CheckInRepository _repository;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Mirrors CheckInDataSource's own offline check. Kept local rather than
  // shared: the Cubit must not depend on the datasource directly (layer
  // boundary), and this is a two-line expression, not worth a shared util.
  static bool _isOffline(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.none) ||
        (results.length == 1 && results.first == ConnectivityResult.none);
  }

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

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}

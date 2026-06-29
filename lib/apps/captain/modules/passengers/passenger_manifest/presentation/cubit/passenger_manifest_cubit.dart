import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/passenger.dart';
import '../../domain/usecases/get_trip_passengers_usecase.dart';
import '../../domain/usecases/update_passenger_status_usecase.dart';
import '../../domain/usecases/watch_trip_passengers_usecase.dart';
import 'passenger_manifest_state.dart';

class PassengerManifestCubit extends Cubit<PassengerManifestState> {
  PassengerManifestCubit({
    required GetTripPassengersUseCase getTripPassengers,
    required WatchTripPassengersUseCase watchTripPassengers,
    required UpdatePassengerStatusUseCase updatePassengerStatus,
  })  : _getTripPassengers = getTripPassengers,
        _watchTripPassengers = watchTripPassengers,
        _updatePassengerStatus = updatePassengerStatus,
        super(const PassengerManifestLoading());

  final GetTripPassengersUseCase _getTripPassengers;
  final WatchTripPassengersUseCase _watchTripPassengers;
  final UpdatePassengerStatusUseCase _updatePassengerStatus;
  StreamSubscription<void>? _subscription;
  String? _tripId;

  Future<void> load(String tripId) async {
    _tripId = tripId;
    emit(const PassengerManifestLoading());
    try {
      emit(PassengerManifestLoaded(await _getTripPassengers(tripId)));
      _subscription?.cancel();
      _subscription = _watchTripPassengers(tripId).listen((_) => _reload());
    } catch (error) {
      emit(PassengerManifestError(error.toString()));
    }
  }

  Future<void> updateStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
  }) async {
    final current = state;
    if (current is! PassengerManifestLoaded) return;
    // Optimistic update
    final updated = current.passengers.map((p) {
      return p.id == tripPassengerId ? p.copyWith(status: status) : p;
    }).toList();
    emit(PassengerManifestLoaded(updated));
    try {
      await _updatePassengerStatus(
        tripPassengerId: tripPassengerId,
        status: status,
      );
    } catch (e) {
      // Rollback on failure
      emit(current);
      emit(PassengerManifestUpdateError(current.passengers, e.toString()));
    }
  }

  Future<void> _reload() async {
    if (_tripId == null) return;
    try {
      emit(PassengerManifestLoaded(await _getTripPassengers(_tripId!)));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

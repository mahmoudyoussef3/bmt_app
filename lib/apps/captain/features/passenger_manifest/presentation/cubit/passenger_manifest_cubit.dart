import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_trip_passengers_usecase.dart';
import '../../domain/usecases/watch_trip_passengers_usecase.dart';
import 'passenger_manifest_state.dart';

class PassengerManifestCubit extends Cubit<PassengerManifestState> {
  PassengerManifestCubit({
    required GetTripPassengersUseCase getTripPassengers,
    required WatchTripPassengersUseCase watchTripPassengers,
  }) : _getTripPassengers = getTripPassengers,
       _watchTripPassengers = watchTripPassengers,
       super(const PassengerManifestLoading());

  final GetTripPassengersUseCase _getTripPassengers;
  final WatchTripPassengersUseCase _watchTripPassengers;
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

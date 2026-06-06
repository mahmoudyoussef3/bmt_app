import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_trip_passengers_usecase.dart';
import 'passenger_manifest_state.dart';

class PassengerManifestCubit extends Cubit<PassengerManifestState> {
  PassengerManifestCubit(this._getTripPassengers)
    : super(const PassengerManifestLoading());

  final GetTripPassengersUseCase _getTripPassengers;

  Future<void> load(String tripId) async {
    emit(const PassengerManifestLoading());
    try {
      emit(PassengerManifestLoaded(await _getTripPassengers(tripId)));
    } catch (error) {
      emit(PassengerManifestError(error.toString()));
    }
  }
}

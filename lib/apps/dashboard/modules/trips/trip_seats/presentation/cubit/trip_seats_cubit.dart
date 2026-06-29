import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../domain/usecases/trip_seats_usecases.dart';

sealed class TripSeatsState {
  const TripSeatsState();
}

class TripSeatsInitial extends TripSeatsState {
  const TripSeatsInitial();
}

class TripSeatsLoading extends TripSeatsState {
  const TripSeatsLoading();
}

class TripSeatsError extends TripSeatsState {
  final String message;
  const TripSeatsError(this.message);
}

class TripSeatsSuccess extends TripSeatsState {
  final OperationTrip trip;
  const TripSeatsSuccess(this.trip);
}

class TripSeatsCubit extends Cubit<TripSeatsState> {
  final UpdateSeatStateUseCase _updateSeatState;

  TripSeatsCubit(this._updateSeatState) : super(const TripSeatsInitial());

  Future<OperationTrip?> changeSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) async {
    emit(const TripSeatsLoading());
    try {
      final updated = await _updateSeatState(tripId, seatId, state);
      emit(TripSeatsSuccess(updated));
      return updated;
    } catch (e) {
      emit(TripSeatsError(e.toString()));
      return null;
    }
  }

  void reset() {
    emit(const TripSeatsInitial());
  }
}

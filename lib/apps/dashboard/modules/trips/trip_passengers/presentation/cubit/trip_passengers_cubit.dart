import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../domain/usecases/trip_passengers_usecases.dart';

sealed class TripPassengersState {
  const TripPassengersState();
}

class TripPassengersInitial extends TripPassengersState {
  const TripPassengersInitial();
}

class TripPassengersLoading extends TripPassengersState {
  const TripPassengersLoading();
}

class TripPassengersError extends TripPassengersState {
  final String message;
  const TripPassengersError(this.message);
}

class TripPassengersSuccess extends TripPassengersState {
  final OperationTrip trip;
  const TripPassengersSuccess(this.trip);
}

class TripPassengersCubit extends Cubit<TripPassengersState> {
  final UpdatePassengerUseCase _updatePassenger;
  final CancelPassengerUseCase _cancelPassenger;
  final MovePassengerUseCase _movePassenger;

  TripPassengersCubit({
    required UpdatePassengerUseCase updatePassenger,
    required CancelPassengerUseCase cancelPassenger,
    required MovePassengerUseCase movePassenger,
  }) : _updatePassenger = updatePassenger,
       _cancelPassenger = cancelPassenger,
       _movePassenger = movePassenger,
       super(const TripPassengersInitial());

  Future<OperationTrip?> editPassenger(
    String tripId,
    TripPassenger passenger,
  ) async {
    emit(const TripPassengersLoading());
    try {
      final updated = await _updatePassenger(tripId, passenger);
      emit(TripPassengersSuccess(updated));
      return updated;
    } catch (e) {
      emit(TripPassengersError(e.toString()));
      return null;
    }
  }

  Future<OperationTrip?> cancelBooking(
    String tripId,
    String passengerId,
  ) async {
    emit(const TripPassengersLoading());
    try {
      final updated = await _cancelPassenger(tripId, passengerId);
      emit(TripPassengersSuccess(updated));
      return updated;
    } catch (e) {
      emit(TripPassengersError(e.toString()));
      return null;
    }
  }

  Future<OperationTrip?> relocatePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) async {
    emit(const TripPassengersLoading());
    try {
      final updated = await _movePassenger(tripId, passengerId, seatLabel);
      emit(TripPassengersSuccess(updated));
      return updated;
    } catch (e) {
      emit(TripPassengersError(e.toString()));
      return null;
    }
  }

  void reset() {
    emit(const TripPassengersInitial());
  }
}

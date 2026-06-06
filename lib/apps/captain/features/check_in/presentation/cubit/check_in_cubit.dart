import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/usecases/check_passenger_usecase.dart';
import 'check_in_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit(this._checkPassenger) : super(const CheckInReady());

  final CheckPassengerUseCase _checkPassenger;

  Future<void> check({
    required String tripId,
    required String passengerId,
    required CheckInStatus status,
  }) async {
    emit(const CheckInLoading());
    try {
      emit(
        CheckInReady(
          result: await _checkPassenger(
            tripId: tripId,
            passengerId: passengerId,
            status: status,
          ),
        ),
      );
    } catch (error) {
      emit(CheckInError(error.toString()));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_daily_booking_data_usecase.dart';
import 'daily_booking_state.dart';

/// Loads the daily direct-booking flow data.
class DailyBookingCubit extends Cubit<DailyBookingState> {
  DailyBookingCubit(this._getDailyBookingData)
    : super(const DailyBookingLoading());

  final GetDailyBookingDataUseCase _getDailyBookingData;
  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    emit(const DailyBookingLoading());
    try {
      emit(DailyBookingLoaded(await _getDailyBookingData()));
    } catch (error) {
      emit(DailyBookingError(error.toString()));
    } finally {
      _inFlight = false;
    }
  }
}

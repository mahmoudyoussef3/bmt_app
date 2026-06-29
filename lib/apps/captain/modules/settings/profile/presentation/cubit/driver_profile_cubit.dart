import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_driver_profile_usecase.dart';
import 'driver_profile_state.dart';

class DriverProfileCubit extends Cubit<DriverProfileState> {
  DriverProfileCubit(this._getProfile) : super(const DriverProfileLoading());

  final GetDriverProfileUseCase _getProfile;

  Future<void> load() async {
    emit(const DriverProfileLoading());
    try {
      emit(DriverProfileLoaded(await _getProfile()));
    } catch (e) {
      emit(DriverProfileError(e.toString()));
    }
  }

  Future<void> refresh() => load();
}

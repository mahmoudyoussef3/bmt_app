import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_settings_data_usecase.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._getSettingsData) : super(const SettingsLoading());

  final GetSettingsDataUseCase _getSettingsData;

  Future<void> load() async {
    emit(const SettingsLoading());
    try {
      final data = await _getSettingsData();
      emit(SettingsLoaded(data));
    } catch (error) {
      emit(SettingsError(error.toString()));
    }
  }
}

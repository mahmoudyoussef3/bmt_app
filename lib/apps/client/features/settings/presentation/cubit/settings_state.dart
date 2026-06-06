import '../../domain/entities/settings_data.dart';

sealed class SettingsState {
  const SettingsState();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.data);

  final SettingsData data;
}

class SettingsError extends SettingsState {
  const SettingsError(this.message);

  final String message;
}

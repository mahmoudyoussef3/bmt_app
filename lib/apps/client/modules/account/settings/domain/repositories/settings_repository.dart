import '../entities/settings_data.dart';

abstract class SettingsRepository {
  Future<SettingsData> getSettingsData();
}

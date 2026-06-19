import '../../domain/entities/settings_data.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/supabase_settings_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._datasource);

  final SettingsDatasource _datasource;

  @override
  Future<SettingsData> getSettingsData() {
    return _datasource.getSettingsData();
  }
}

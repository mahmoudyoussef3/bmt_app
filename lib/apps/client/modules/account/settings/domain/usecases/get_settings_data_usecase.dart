import '../entities/settings_data.dart';
import '../repositories/settings_repository.dart';

class GetSettingsDataUseCase {
  const GetSettingsDataUseCase(this._repository);

  final SettingsRepository _repository;

  Future<SettingsData> call() {
    return _repository.getSettingsData();
  }
}

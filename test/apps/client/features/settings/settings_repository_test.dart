import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/settings/data/datasources/mock_settings_datasource.dart';
import 'package:bmt_app/apps/client/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:bmt_app/apps/client/features/settings/domain/usecases/get_settings_data_usecase.dart';

void main() {
  group('Client settings repository', () {
    test('returns settings seed data through use case', () async {
      final repository = SettingsRepositoryImpl(const MockSettingsDatasource());
      final data = await GetSettingsDataUseCase(repository)();

      expect(data.selectedLanguage, 'en');
      expect(data.selectedTheme, 'system');
      expect(data.userName, 'Ahmed Hassan');
      expect(data.activeSessions, hasLength(4));
      expect(data.notificationsSettings['trips']?['push'], isTrue);
      expect(data.faqs, hasLength(6));
      expect(data.termsTableOfContents.last['progress'], 0.9);
    });
  });
}

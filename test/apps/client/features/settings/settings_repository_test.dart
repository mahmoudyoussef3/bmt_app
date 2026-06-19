import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/settings/data/datasources/supabase_settings_datasource.dart';
import 'package:bmt_app/apps/client/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:bmt_app/apps/client/features/settings/domain/entities/settings_data.dart';
import 'package:bmt_app/apps/client/features/settings/domain/usecases/get_settings_data_usecase.dart';

void main() {
  group('Client settings repository', () {
    test('returns settings seed data through use case', () async {
      final repository = SettingsRepositoryImpl(
        const _FakeSettingsDatasource(),
      );
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

class _FakeSettingsDatasource implements SettingsDatasource {
  const _FakeSettingsDatasource();

  @override
  Future<SettingsData> getSettingsData() async {
    return const SettingsData(
      selectedLanguage: 'en',
      selectedTheme: 'system',
      userName: 'Ahmed Hassan',
      userEmail: 'ahmed@example.com',
      userPhone: '01000000000',
      activeSessions: [
        {'id': 's1', 'device': 'iPhone', 'platform': 'iOS', 'time': 'Now'},
        {'id': 's2', 'device': 'Chrome', 'platform': 'Web', 'time': 'Today'},
        {
          'id': 's3',
          'device': 'Android',
          'platform': 'Android',
          'time': 'Yesterday',
        },
        {
          'id': 's4',
          'device': 'Safari',
          'platform': 'Web',
          'time': 'Last week',
        },
      ],
      notificationsSettings: {
        'trips': {'push': true, 'sms': true, 'email': false},
      },
      faqs: [
        {'id': 'faq1', 'question': 'Q1', 'answer': 'A1'},
        {'id': 'faq2', 'question': 'Q2', 'answer': 'A2'},
        {'id': 'faq3', 'question': 'Q3', 'answer': 'A3'},
        {'id': 'faq4', 'question': 'Q4', 'answer': 'A4'},
        {'id': 'faq5', 'question': 'Q5', 'answer': 'A5'},
        {'id': 'faq6', 'question': 'Q6', 'answer': 'A6'},
      ],
      termsTableOfContents: [
        {'title': 'Intro', 'progress': 0.1},
        {'title': 'Rules', 'progress': 0.9},
      ],
    );
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/profile/data/datasources/mock_profile_datasource.dart';
import 'package:bmt_app/apps/client/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/get_profile_data_usecase.dart';

void main() {
  group('Client profile', () {
    test('returns profile identity and menu sections', () async {
      const repository = ProfileRepositoryImpl(MockProfileDatasource());

      final data = await GetProfileDataUseCase(repository)();

      expect(data.profile.name, 'Ahmed Hassan');
      expect(data.profile.badge, 'Premium');
      expect(data.sections, hasLength(5));
      expect(data.sections[1].items.first.route, '/trips');
      expect(data.sections.last.items.last.route, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/domain/repositories/profile_repository.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/get_profile_data_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({required this.results});

  /// Consumed one per call — a `null` entry makes that call throw.
  final List<ClientProfileData?> results;
  int calls = 0;

  @override
  Future<ClientProfileData> getProfileData() async {
    final result = results[calls++];
    if (result == null) throw Exception('network down');
    return result;
  }
}

const _profileData = ClientProfileData(
  profile: ClientProfile(
    initials: 'MY',
    name: 'Mahmoud',
    email: 'mahmoud@example.com',
    badge: 'Member',
  ),
  sections: [],
);

ProfileCubit _cubit(List<ClientProfileData?> results) =>
    ProfileCubit(GetProfileDataUseCase(_FakeProfileRepository(results: results)));

void main() {
  group('ProfileCubit.load', () {
    test('initial load emits ProfileLoaded on success', () async {
      final cubit = _cubit([_profileData]);
      expect(cubit.state, isA<ProfileLoading>());

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<ProfileLoaded>());
      expect((state as ProfileLoaded).data.profile.name, 'Mahmoud');
      expect(state.refreshFailure, isNull);
    });

    test('initial load emits ProfileError on failure', () async {
      final cubit = _cubit([null]);

      await cubit.load();

      expect(cubit.state, isA<ProfileError>());
    });

    test('refresh keeps loaded content instead of flashing the skeleton',
        () async {
      final cubit = _cubit([_profileData, _profileData]);
      await cubit.load();

      final emitted = <ProfileState>[];
      final subscription = cubit.stream.listen(emitted.add);
      await cubit.load();
      await subscription.cancel();

      expect(emitted.whereType<ProfileLoading>(), isEmpty);
      expect(cubit.state, isA<ProfileLoaded>());
    });

    test('failed refresh keeps content and reports the failure', () async {
      final cubit = _cubit([_profileData, null]);
      await cubit.load();

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<ProfileLoaded>());
      expect((state as ProfileLoaded).data.profile.name, 'Mahmoud');
      expect(state.refreshFailure, isNotNull);
    });

    test('retry after initial failure can still succeed', () async {
      final cubit = _cubit([null, _profileData]);
      await cubit.load();
      expect(cubit.state, isA<ProfileError>());

      await cubit.load();

      expect(cubit.state, isA<ProfileLoaded>());
    });
  });
}

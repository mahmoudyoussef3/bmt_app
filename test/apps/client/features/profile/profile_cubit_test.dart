import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/domain/repositories/profile_repository.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/get_profile_data_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({required this.results, this.updateFails = false});

  /// Consumed one per call — a `null` entry makes that call throw.
  final List<ClientProfile?> results;
  final bool updateFails;

  int calls = 0;
  ClientProfile? lastUpdate;

  @override
  Future<ClientProfile> getProfile() async {
    final result = results[calls++];
    if (result == null) throw Exception('network down');
    return result;
  }

  @override
  Future<ClientProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (updateFails) throw Exception('phone already used');
    lastUpdate = _profile.copyWith(name: name, email: email, phone: phone);
    return lastUpdate!;
  }
}

const _profile = ClientProfile(
  id: 'client-1',
  name: 'Mahmoud Youssef',
  email: 'mahmoud@example.com',
  phone: '+201012345678',
  completedTrips: 12,
  upcomingTrips: 2,
);

ProfileCubit _cubit(List<ClientProfile?> results, {bool updateFails = false}) {
  final repository = _FakeProfileRepository(
    results: results,
    updateFails: updateFails,
  );
  return ProfileCubit(
    GetProfileDataUseCase(repository),
    UpdateProfileUseCase(repository),
  );
}

void main() {
  group('ProfileCubit.load', () {
    test('initial load emits ProfileLoaded on success', () async {
      final cubit = _cubit([_profile]);
      expect(cubit.state, isA<ProfileLoading>());

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<ProfileLoaded>());
      expect((state as ProfileLoaded).profile.name, 'Mahmoud Youssef');
      expect(state.profile.completedTrips, 12);
      expect(state.refreshFailed, isFalse);
    });

    test('initial load emits ProfileError on failure', () async {
      final cubit = _cubit([null]);

      await cubit.load();

      expect(cubit.state, isA<ProfileError>());
    });

    test(
      'refresh keeps loaded content instead of flashing the skeleton',
      () async {
        final cubit = _cubit([_profile, _profile]);
        await cubit.load();

        final emitted = <ProfileState>[];
        final subscription = cubit.stream.listen(emitted.add);
        await cubit.load();
        await subscription.cancel();

        expect(emitted.whereType<ProfileLoading>(), isEmpty);
        expect(cubit.state, isA<ProfileLoaded>());
      },
    );

    test('failed refresh keeps content and reports the failure', () async {
      final cubit = _cubit([_profile, null]);
      await cubit.load();

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<ProfileLoaded>());
      expect((state as ProfileLoaded).profile.name, 'Mahmoud Youssef');
      expect(state.refreshFailed, isTrue);
    });

    test('retry after initial failure can still succeed', () async {
      final cubit = _cubit([null, _profile]);
      await cubit.load();
      expect(cubit.state, isA<ProfileError>());

      await cubit.load();

      expect(cubit.state, isA<ProfileLoaded>());
    });
  });

  group('ProfileCubit.updateProfile', () {
    test('a successful save replaces the profile on screen', () async {
      final cubit = _cubit([_profile]);
      await cubit.load();

      await cubit.updateProfile(
        name: 'Mahmoud Y',
        email: 'new@example.com',
        phone: '01112345678',
      );

      final state = cubit.state as ProfileLoaded;
      expect(state.editStatus, ProfileEditStatus.success);
      expect(state.profile.name, 'Mahmoud Y');
      // The use case normalises before the repository ever sees it.
      expect(state.profile.phone, '+201112345678');
      expect(state.fieldErrors, isEmpty);
    });

    test(
      'a rejected field is reported against that field, not as a failure',
      () async {
        final cubit = _cubit([_profile]);
        await cubit.load();

        await cubit.updateProfile(
          name: 'Mahmoud',
          email: 'not-an-email',
          phone: '+201012345678',
        );

        final state = cubit.state as ProfileLoaded;
        expect(state.editStatus, ProfileEditStatus.failure);
        expect(
          state.fieldErrors[ProfileField.email],
          ProfileFieldError.invalidEmail,
        );
        expect(state.saveError, isNull);
        // The rider's existing details must survive a rejected edit.
        expect(state.profile.email, 'mahmoud@example.com');
      },
    );

    test(
      'a backend failure surfaces as a save error, not a field error',
      () async {
        final cubit = _cubit([_profile], updateFails: true);
        await cubit.load();

        await cubit.updateProfile(
          name: 'Mahmoud Youssef',
          email: 'mahmoud@example.com',
          phone: '+201012345678',
        );

        final state = cubit.state as ProfileLoaded;
        expect(state.editStatus, ProfileEditStatus.failure);
        expect(state.saveError, contains('phone already used'));
        expect(state.fieldErrors, isEmpty);
      },
    );

    test(
      'resetEditStatus clears a stale error before the sheet reopens',
      () async {
        final cubit = _cubit([_profile]);
        await cubit.load();
        await cubit.updateProfile(name: '', email: '', phone: '');
        expect((cubit.state as ProfileLoaded).fieldErrors, isNotEmpty);

        cubit.resetEditStatus();

        final state = cubit.state as ProfileLoaded;
        expect(state.editStatus, ProfileEditStatus.idle);
        expect(state.fieldErrors, isEmpty);
        expect(state.saveError, isNull);
      },
    );

    test('a save is ignored while one is already in flight', () async {
      final cubit = _cubit([_profile]);
      await cubit.load();

      final first = cubit.updateProfile(
        name: 'Mahmoud Youssef',
        email: 'mahmoud@example.com',
        phone: '+201012345678',
      );
      // Fires while the first save is still running.
      await cubit.updateProfile(name: '', email: '', phone: '');
      await first;

      final state = cubit.state as ProfileLoaded;
      expect(state.editStatus, ProfileEditStatus.success);
      expect(state.fieldErrors, isEmpty);
    });
  });
}

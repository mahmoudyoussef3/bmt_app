import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/domain/repositories/profile_repository.dart';
import 'package:bmt_app/apps/client/features/profile/domain/usecases/update_profile_usecase.dart';

class _RecordingRepository implements ProfileRepository {
  String? name;
  String? email;
  String? phone;

  @override
  Future<ClientProfile> getProfile() async => throw UnimplementedError();

  @override
  Future<ClientProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    this.name = name;
    this.email = email;
    this.phone = phone;
    return ClientProfile(id: 'c1', name: name, email: email, phone: phone);
  }
}

/// Runs [action] and returns the field rejections it raised. Fails the test if
/// the call was accepted — a validation test that silently passes is worse than
/// no test.
Future<Map<ProfileField, ProfileFieldError>> _errorsOf(
  Future<void> Function() action,
) async {
  try {
    await action();
  } on ProfileValidationException catch (error) {
    return error.errors;
  }
  fail('Expected the update to be rejected, but it was accepted.');
}

void main() {
  late _RecordingRepository repository;
  late UpdateProfileUseCase usecase;

  setUp(() {
    repository = _RecordingRepository();
    usecase = UpdateProfileUseCase(repository);
  });

  group('validation', () {
    test('rejects every empty field at once', () async {
      final errors = await _errorsOf(
        () => usecase(name: '', email: '', phone: ''),
      );

      expect(errors[ProfileField.name], ProfileFieldError.required);
      expect(errors[ProfileField.phone], ProfileFieldError.required);
      expect(errors[ProfileField.email], ProfileFieldError.required);
    });

    test('rejects a name that is not a name', () async {
      final errors = await _errorsOf(
        () => usecase(name: 'Mo', email: 'a@b.com', phone: '01012345678'),
      );

      expect(errors[ProfileField.name], ProfileFieldError.nameTooShort);
    });

    test('rejects a malformed email', () async {
      final errors = await _errorsOf(
        () => usecase(name: 'Mahmoud', email: 'nope', phone: '01012345678'),
      );

      expect(errors[ProfileField.email], ProfileFieldError.invalidEmail);
    });

    test('rejects a number that is not an Egyptian mobile', () async {
      final errors = await _errorsOf(
        () => usecase(name: 'Mahmoud', email: 'a@b.com', phone: '0221234567'),
      );

      expect(errors[ProfileField.phone], ProfileFieldError.invalidPhone);
    });

    test('nothing reaches the repository when validation fails', () async {
      await _errorsOf(() => usecase(name: '', email: '', phone: ''));

      expect(repository.name, isNull);
    });
  });

  group('normalisation', () {
    test('a local 01… number is stored in E.164', () async {
      await usecase(
        name: 'Mahmoud Youssef',
        email: 'MAHMOUD@Example.com ',
        phone: '010 1234 5678',
      );

      expect(repository.phone, '+201012345678');
    });

    test(
      'the email is trimmed and lower-cased so it stays one identity',
      () async {
        await usecase(
          name: '  Mahmoud Youssef  ',
          email: '  MAHMOUD@Example.COM  ',
          phone: '+201012345678',
        );

        expect(repository.email, 'mahmoud@example.com');
        expect(repository.name, 'Mahmoud Youssef');
      },
    );

    test('an already-normalised number is left alone', () async {
      await usecase(
        name: 'Mahmoud Youssef',
        email: 'a@b.com',
        phone: '+201512345678',
      );

      expect(repository.phone, '+201512345678');
    });
  });
}

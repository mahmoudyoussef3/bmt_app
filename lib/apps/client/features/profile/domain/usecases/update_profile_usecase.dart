import 'package:bmt_app/core/validation/contact_validation.dart';

import '../entities/client_profile.dart';
import '../repositories/profile_repository.dart';

/// Why a single field was rejected. The reason is returned as an enum rather
/// than a sentence so the presentation layer can render it in the rider's
/// language.
enum ProfileFieldError { required, invalidEmail, invalidPhone, nameTooShort }

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.errors);

  final Map<ProfileField, ProfileFieldError> errors;
}

/// Validates and persists the rider's contact details.
///
/// Validation lives here rather than in the form so that every caller — the
/// edit sheet today, a "complete your profile" prompt tomorrow — enforces the
/// same rules, and so the rules are testable without a widget tree.
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ClientProfile> call({
    required String name,
    required String email,
    required String phone,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final normalizedPhone = ContactValidation.normalizeEgyptianPhone(phone);

    final errors = <ProfileField, ProfileFieldError>{};

    if (trimmedName.isEmpty) {
      errors[ProfileField.name] = ProfileFieldError.required;
    } else if (trimmedName.length < 3) {
      errors[ProfileField.name] = ProfileFieldError.nameTooShort;
    }

    if (phone.trim().isEmpty) {
      errors[ProfileField.phone] = ProfileFieldError.required;
    } else if (!ContactValidation.isValidEgyptianPhone(phone)) {
      errors[ProfileField.phone] = ProfileFieldError.invalidPhone;
    }

    if (trimmedEmail.isEmpty) {
      errors[ProfileField.email] = ProfileFieldError.required;
    } else if (!ContactValidation.isValidEmail(trimmedEmail)) {
      errors[ProfileField.email] = ProfileFieldError.invalidEmail;
    }

    if (errors.isNotEmpty) throw ProfileValidationException(errors);

    return _repository.updateProfile(
      name: trimmedName,
      email: trimmedEmail,
      phone: normalizedPhone,
    );
  }
}

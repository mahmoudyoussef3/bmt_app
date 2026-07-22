import '../entities/office_onboarding.dart';
import '../entities/platform_office.dart';
import '../entities/platform_office_details.dart';
import '../repositories/platform_admin_repository.dart';

class GetPlatformOfficesUseCase {
  const GetPlatformOfficesUseCase(this._repository);
  final PlatformAdminRepository _repository;
  Future<List<PlatformOffice>> call() => _repository.getOffices();
}

class GetPlatformOfficeDetailsUseCase {
  const GetPlatformOfficeDetailsUseCase(this._repository);
  final PlatformAdminRepository _repository;

  Future<PlatformOfficeDetails> call(String officeId) {
    if (officeId.trim().isEmpty) {
      throw ArgumentError.value(officeId, 'officeId', 'must not be empty');
    }
    return _repository.getOfficeDetails(officeId);
  }
}

/// Onboards an office. Refuses locally before touching the network when the
/// request is malformed — the server validates it again regardless, but a round
/// trip to be told the username is too short is a round trip wasted.
class OnboardOfficeUseCase {
  const OnboardOfficeUseCase(this._repository);
  final PlatformAdminRepository _repository;

  Future<OfficeOnboardingResult> call(OfficeOnboardingRequest request) {
    final errors = request.validate();
    if (errors.isNotEmpty) {
      throw OfficeOnboardingValidationException(errors);
    }
    return _repository.onboardOffice(request);
  }
}

class SetOfficeListingUseCase {
  const SetOfficeListingUseCase(this._repository);
  final PlatformAdminRepository _repository;

  Future<void> call(String officeId, String listingStatus) {
    if (!const {'draft', 'listed', 'unlisted'}.contains(listingStatus)) {
      throw ArgumentError.value(listingStatus, 'listingStatus');
    }
    return _repository.setListingStatus(officeId, listingStatus);
  }
}

class SetOfficeStatusUseCase {
  const SetOfficeStatusUseCase(this._repository);
  final PlatformAdminRepository _repository;

  Future<void> call(String officeId, String status) {
    if (!const {'active', 'paused', 'suspended', 'archived'}.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    return _repository.setOfficeStatus(officeId, status);
  }
}

/// Carries the per-field errors so the form can mark the offending inputs
/// instead of showing one message with no anchor.
class OfficeOnboardingValidationException implements Exception {
  const OfficeOnboardingValidationException(this.errors);
  final Map<String, String> errors;

  @override
  String toString() => errors.values.first;
}

import '../entities/office_onboarding.dart';
import '../entities/platform_office.dart';
import '../entities/platform_office_details.dart';

abstract class PlatformAdminRepository {
  /// Every office on the platform, including the ones no client can see.
  Future<List<PlatformOffice>> getOffices();

  /// One office in full: counts, its operators, and its marketplace preview.
  Future<PlatformOfficeDetails> getOfficeDetails(String officeId);

  /// Creates an office and its first dashboard administrator.
  Future<OfficeOnboardingResult> onboardOffice(OfficeOnboardingRequest request);

  /// Publishes or withdraws an office from the client marketplace.
  Future<void> setListingStatus(String officeId, String listingStatus);

  /// Changes an office's operational status. Distinct from listing: suspending
  /// locks the office's own staff and captains out, withdrawing does not.
  Future<void> setOfficeStatus(String officeId, String status);
}

import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_office.dart';

abstract class PlatformAdminDatasource {
  Future<List<PlatformOffice>> getOffices();
  Future<OfficeOnboardingResult> onboardOffice(OfficeOnboardingRequest request);
  Future<void> setListingStatus(String officeId, String listingStatus);
  Future<void> setOfficeStatus(String officeId, String status);
}

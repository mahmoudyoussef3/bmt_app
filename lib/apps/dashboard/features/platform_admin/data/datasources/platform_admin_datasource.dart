import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_details.dart';

abstract class PlatformAdminDatasource {
  Future<List<PlatformOffice>> getOffices();
  Future<PlatformAnalytics> getAnalytics({int windowDays});
  Future<PlatformOfficeDetails> getOfficeDetails(String officeId);
  Future<OfficeOnboardingResult> onboardOffice(OfficeOnboardingRequest request);
  Future<void> setListingStatus(String officeId, String listingStatus);
  Future<void> setOfficeStatus(String officeId, String status);
}

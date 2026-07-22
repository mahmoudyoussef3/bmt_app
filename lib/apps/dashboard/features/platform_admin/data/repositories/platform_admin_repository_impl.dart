import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_details.dart';
import '../../domain/repositories/platform_admin_repository.dart';
import '../datasources/platform_admin_datasource.dart';

class PlatformAdminRepositoryImpl implements PlatformAdminRepository {
  const PlatformAdminRepositoryImpl(this._datasource);

  final PlatformAdminDatasource _datasource;

  @override
  Future<List<PlatformOffice>> getOffices() => _datasource.getOffices();

  @override
  Future<PlatformOfficeDetails> getOfficeDetails(String officeId) =>
      _datasource.getOfficeDetails(officeId);

  @override
  Future<OfficeOnboardingResult> onboardOffice(
    OfficeOnboardingRequest request,
  ) => _datasource.onboardOffice(request);

  @override
  Future<void> setListingStatus(String officeId, String listingStatus) =>
      _datasource.setListingStatus(officeId, listingStatus);

  @override
  Future<void> setOfficeStatus(String officeId, String status) =>
      _datasource.setOfficeStatus(officeId, status);
}

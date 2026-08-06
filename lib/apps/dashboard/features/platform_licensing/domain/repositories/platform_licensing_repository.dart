import '../entities/licensing_catalog.dart';
import '../entities/office_license.dart';

/// The console's contract with the licensing subsystem.
///
/// Mirrors the datasource one-for-one: this module has no mapping to do,
/// because the RPCs already return the domain shape and the entities parse it.
/// The interface exists so the presentation layer never imports `data/`.
abstract class PlatformLicensingRepository {
  Future<FeatureCatalog> catalog();
  Future<void> upsertFeature(Map<String, dynamic> payload);
  Future<void> setFeatureStatus(String key, String status);

  Future<List<LicensingPlan>> plans();
  Future<PlanDetail> planDetail(String planId);
  Future<PlanDetail> savePlan(Map<String, dynamic> payload);
  Future<PlanDetail> clonePlan(String planId, String newKey, String newName);
  Future<Map<String, dynamic>> comparePlans(List<String> planIds);
  Future<Map<String, dynamic>> previewPlan(String planId);

  Future<List<OfficeLicenseRow>> licenses();
  Future<OfficeLicenseDetail> officeLicense(String officeId);
  Future<OfficeLicenseDetail> assignPlan(
    String officeId,
    String planId, {
    String cycle,
    Map<String, dynamic> options,
  });
  Future<OfficeLicenseDetail> setLicenseStatus(
    String officeId,
    String status,
    String reason,
  );
  Future<OfficeLicenseDetail> startTrial(
    String officeId,
    String planId,
    int days,
  );
  Future<OfficeLicenseDetail> extendTrial(
    String officeId,
    int days,
    String reason,
  );

  Future<OfficeLicenseDetail> setOverride(
    String officeId,
    String featureKey,
    Object? value,
    String reason, {
    DateTime? expiresAt,
  });
  Future<OfficeLicenseDetail> clearOverride(
    String officeId,
    String featureKey,
    String reason,
  );

  Future<BillingOverview> billing({String? officeId, String? status});
  Future<void> issueInvoice(String officeId, {Map<String, dynamic> options});
  Future<void> recordPayment(
    String invoiceId,
    String method,
    String? reference,
  );
  Future<void> voidInvoice(String invoiceId, String reason);

  Future<List<OfficeUsageRow>> usage();
  Future<List<LicenseAuditEntry>> audit({
    Map<String, dynamic> filters,
    int limit,
    int offset,
  });
  Future<LicensingHealth> health();
  Future<LicensingSettings> settings();
  Future<LicensingSettings> updateSettings(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> runLifecycle();
  Future<Map<String, dynamic>> runBillingCycle();
}

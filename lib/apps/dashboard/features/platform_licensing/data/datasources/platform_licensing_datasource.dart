import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';

/// Everything the platform-owner console reads and writes.
///
/// Every one of these lands on an RPC that re-checks `is_platform_admin()`
/// server-side, so this interface carries no authorisation of its own — the
/// nav item that reveals it is a hint, and the boundary is in Postgres.
abstract class PlatformLicensingDatasource {
  
  Future<FeatureCatalog> catalog();
  Future<void> upsertFeature(Map<String, dynamic> payload);
  Future<void> setFeatureStatus(String key, String status);

  Future<List<LicensingPlan>> plans();
  Future<PlanDetail> planDetail(String planId);

  /// Saves the plan and its full value map, snapshotting a revision first.
  ///
  /// The value map is replaced WHOLESALE: a key omitted from it is deleted,
  /// which means "fall through to the catalog default". Callers must therefore
  /// send the complete map, not a patch.
  Future<PlanDetail> savePlan(Map<String, dynamic> payload);

  Future<PlanDetail> clonePlan(String planId, String newKey, String newName);
  Future<Map<String, dynamic>> comparePlans(List<String> planIds);

  /// Runs the real resolver against a hypothetical office on this plan. Not a
  /// reimplementation — a preview that can drift is worse than no preview.
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

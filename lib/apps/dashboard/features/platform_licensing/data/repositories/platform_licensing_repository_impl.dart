import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';
import '../../domain/repositories/platform_licensing_repository.dart';
import '../datasources/platform_licensing_datasource.dart';

class PlatformLicensingRepositoryImpl implements PlatformLicensingRepository {
  PlatformLicensingRepositoryImpl(this._datasource);

  final PlatformLicensingDatasource _datasource;

  @override
  Future<FeatureCatalog> catalog() => _datasource.catalog();

  @override
  Future<void> upsertFeature(Map<String, dynamic> payload) =>
      _datasource.upsertFeature(payload);

  @override
  Future<void> setFeatureStatus(String key, String status) =>
      _datasource.setFeatureStatus(key, status);

  @override
  Future<List<LicensingPlan>> plans() => _datasource.plans();

  @override
  Future<PlanDetail> planDetail(String planId) =>
      _datasource.planDetail(planId);

  @override
  Future<PlanDetail> savePlan(Map<String, dynamic> payload) =>
      _datasource.savePlan(payload);

  @override
  Future<PlanDetail> clonePlan(String planId, String newKey, String newName) =>
      _datasource.clonePlan(planId, newKey, newName);

  @override
  Future<Map<String, dynamic>> comparePlans(List<String> planIds) =>
      _datasource.comparePlans(planIds);

  @override
  Future<Map<String, dynamic>> previewPlan(String planId) =>
      _datasource.previewPlan(planId);

  @override
  Future<List<OfficeLicenseRow>> licenses() => _datasource.licenses();

  @override
  Future<OfficeLicenseDetail> officeLicense(String officeId) =>
      _datasource.officeLicense(officeId);

  @override
  Future<OfficeLicenseDetail> assignPlan(
    String officeId,
    String planId, {
    String cycle = 'monthly',
    Map<String, dynamic> options = const {},
  }) =>
      _datasource.assignPlan(officeId, planId, cycle: cycle, options: options);

  @override
  Future<OfficeLicenseDetail> setLicenseStatus(
    String officeId,
    String status,
    String reason,
  ) => _datasource.setLicenseStatus(officeId, status, reason);

  @override
  Future<OfficeLicenseDetail> startTrial(
    String officeId,
    String planId,
    int days,
  ) => _datasource.startTrial(officeId, planId, days);

  @override
  Future<OfficeLicenseDetail> extendTrial(
    String officeId,
    int days,
    String reason,
  ) => _datasource.extendTrial(officeId, days, reason);

  @override
  Future<OfficeLicenseDetail> setOverride(
    String officeId,
    String featureKey,
    Object? value,
    String reason, {
    DateTime? expiresAt,
  }) => _datasource.setOverride(
    officeId,
    featureKey,
    value,
    reason,
    expiresAt: expiresAt,
  );

  @override
  Future<OfficeLicenseDetail> clearOverride(
    String officeId,
    String featureKey,
    String reason,
  ) => _datasource.clearOverride(officeId, featureKey, reason);

  @override
  Future<BillingOverview> billing({String? officeId, String? status}) =>
      _datasource.billing(officeId: officeId, status: status);

  @override
  Future<void> issueInvoice(
    String officeId, {
    Map<String, dynamic> options = const {},
  }) => _datasource.issueInvoice(officeId, options: options);

  @override
  Future<void> recordPayment(
    String invoiceId,
    String method,
    String? reference,
  ) => _datasource.recordPayment(invoiceId, method, reference);

  @override
  Future<void> voidInvoice(String invoiceId, String reason) =>
      _datasource.voidInvoice(invoiceId, reason);

  @override
  Future<List<OfficeUsageRow>> usage() => _datasource.usage();

  @override
  Future<List<LicenseAuditEntry>> audit({
    Map<String, dynamic> filters = const {},
    int limit = 100,
    int offset = 0,
  }) => _datasource.audit(filters: filters, limit: limit, offset: offset);

  @override
  Future<LicensingHealth> health() => _datasource.health();

  @override
  Future<LicensingSettings> settings() => _datasource.settings();

  @override
  Future<LicensingSettings> updateSettings(Map<String, dynamic> payload) =>
      _datasource.updateSettings(payload);

  @override
  Future<Map<String, dynamic>> runLifecycle() => _datasource.runLifecycle();

  @override
  Future<Map<String, dynamic>> runBillingCycle() =>
      _datasource.runBillingCycle();
}

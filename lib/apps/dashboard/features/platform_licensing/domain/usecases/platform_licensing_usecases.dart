import '../entities/licensing_catalog.dart';
import '../entities/office_license.dart';
import '../repositories/platform_licensing_repository.dart';

/// One class per action the console can take.
///
/// Grouped in a single file the way `platform_admin_usecases.dart` groups its
/// own: these are thin, they share one repository, and eleven single-class
/// files would obscure rather than reveal the module's surface.

class GetFeatureCatalogUseCase {
  const GetFeatureCatalogUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<FeatureCatalog> call() => _repo.catalog();
}

class SetFeatureStatusUseCase {
  const SetFeatureStatusUseCase(this._repo);
  final PlatformLicensingRepository _repo;

  /// `active` | `hidden` | `deprecated` | `disabled`. `disabled` is the
  /// platform-wide kill switch and outranks every plan and override.
  Future<void> call(String key, String status) =>
      _repo.setFeatureStatus(key, status);
}

class GetPlansUseCase {
  const GetPlansUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<List<LicensingPlan>> call() => _repo.plans();
}

class GetPlanDetailUseCase {
  const GetPlanDetailUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<PlanDetail> call(String planId) => _repo.planDetail(planId);
}

class SavePlanUseCase {
  const SavePlanUseCase(this._repo);
  final PlatformLicensingRepository _repo;

  /// Snapshots a revision before it writes, so an edit is always reversible and
  /// always explainable. The value map is replaced wholesale — send all of it.
  Future<PlanDetail> call(Map<String, dynamic> payload) =>
      _repo.savePlan(payload);
}

class ClonePlanUseCase {
  const ClonePlanUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<PlanDetail> call(String planId, String key, String name) =>
      _repo.clonePlan(planId, key, name);
}

class PreviewPlanUseCase {
  const PreviewPlanUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<Map<String, dynamic>> call(String planId) => _repo.previewPlan(planId);
}

class ComparePlansUseCase {
  const ComparePlansUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<Map<String, dynamic>> call(List<String> planIds) =>
      _repo.comparePlans(planIds);
}

class GetOfficeLicensesUseCase {
  const GetOfficeLicensesUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<List<OfficeLicenseRow>> call() => _repo.licenses();
}

class GetOfficeLicenseUseCase {
  const GetOfficeLicenseUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<OfficeLicenseDetail> call(String officeId) =>
      _repo.officeLicense(officeId);
}

class AssignPlanUseCase {
  const AssignPlanUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<OfficeLicenseDetail> call(
    String officeId,
    String planId, {
    String cycle = 'monthly',
    Map<String, dynamic> options = const {},
  }) => _repo.assignPlan(officeId, planId, cycle: cycle, options: options);
}

class SetLicenseStatusUseCase {
  const SetLicenseStatusUseCase(this._repo);
  final PlatformLicensingRepository _repo;

  /// Suspension DEGRADES to read-only; it never blacks out. The office keeps
  /// serving passengers who already hold tickets and its captains keep driving.
  Future<OfficeLicenseDetail> call(
    String officeId,
    String status,
    String reason,
  ) => _repo.setLicenseStatus(officeId, status, reason);
}

class ExtendTrialUseCase {
  const ExtendTrialUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<OfficeLicenseDetail> call(String officeId, int days, String reason) =>
      _repo.extendTrial(officeId, days, reason);
}

class SetFeatureOverrideUseCase {
  const SetFeatureOverrideUseCase(this._repo);
  final PlatformLicensingRepository _repo;

  /// [reason] is mandatory and length-checked by the database. An override with
  /// no stated reason becomes a permanent unexplained exception.
  Future<OfficeLicenseDetail> call(
    String officeId,
    String featureKey,
    Object? value,
    String reason, {
    DateTime? expiresAt,
  }) => _repo.setOverride(
    officeId,
    featureKey,
    value,
    reason,
    expiresAt: expiresAt,
  );
}

class ClearFeatureOverrideUseCase {
  const ClearFeatureOverrideUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<OfficeLicenseDetail> call(
    String officeId,
    String featureKey,
    String reason,
  ) => _repo.clearOverride(officeId, featureKey, reason);
}

class GetBillingOverviewUseCase {
  const GetBillingOverviewUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<BillingOverview> call({String? officeId, String? status}) =>
      _repo.billing(officeId: officeId, status: status);
}

class IssueInvoiceUseCase {
  const IssueInvoiceUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<void> call(
    String officeId, {
    Map<String, dynamic> options = const {},
  }) => _repo.issueInvoice(officeId, options: options);
}

class RecordInvoicePaymentUseCase {
  const RecordInvoicePaymentUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<void> call(String invoiceId, String method, String? reference) =>
      _repo.recordPayment(invoiceId, method, reference);
}

class VoidInvoiceUseCase {
  const VoidInvoiceUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<void> call(String invoiceId, String reason) =>
      _repo.voidInvoice(invoiceId, reason);
}

class GetPlatformUsageUseCase {
  const GetPlatformUsageUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<List<OfficeUsageRow>> call() => _repo.usage();
}

class GetLicenseAuditUseCase {
  const GetLicenseAuditUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<List<LicenseAuditEntry>> call({
    Map<String, dynamic> filters = const {},
    int limit = 100,
    int offset = 0,
  }) => _repo.audit(filters: filters, limit: limit, offset: offset);
}

class GetLicensingHealthUseCase {
  const GetLicensingHealthUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<LicensingHealth> call() => _repo.health();
}

class GetLicensingSettingsUseCase {
  const GetLicensingSettingsUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<LicensingSettings> call() => _repo.settings();
}

class UpdateLicensingSettingsUseCase {
  const UpdateLicensingSettingsUseCase(this._repo);
  final PlatformLicensingRepository _repo;

  /// Includes the kill switch. `enforcement_mode = 'off'` disables the entire
  /// subsystem in one row update, without a deploy.
  Future<LicensingSettings> call(Map<String, dynamic> payload) =>
      _repo.updateSettings(payload);
}

class RunLicensingLifecycleUseCase {
  const RunLicensingLifecycleUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<Map<String, dynamic>> call() => _repo.runLifecycle();
}

class RunBillingCycleUseCase {
  const RunBillingCycleUseCase(this._repo);
  final PlatformLicensingRepository _repo;
  Future<Map<String, dynamic>> call() => _repo.runBillingCycle();
}

import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';

/// The licensing console is one cubit driving several independent regions —
/// catalog, plans, licences, billing, usage, audit and health — so the state is
/// the multi-concern shape: one `Loaded` carrying per-section slices and
/// per-section loading flags, rather than a union that would make a failed
/// audit fetch take the plan list down with it.
///
/// Same reasoning `PlatformAdminLoaded` already applies to its analytics slice.
sealed class PlatformLicensingState {
  const PlatformLicensingState();
}

class PlatformLicensingInitial extends PlatformLicensingState {
  const PlatformLicensingInitial();
}

class PlatformLicensingLoading extends PlatformLicensingState {
  const PlatformLicensingLoading();
}

/// The console has no data at all — a failed load, not a failed action.
class PlatformLicensingError extends PlatformLicensingState {
  const PlatformLicensingError(this.message);
  final String message;
}

class PlatformLicensingLoaded extends PlatformLicensingState {
  const PlatformLicensingLoaded({
    this.catalog = FeatureCatalog.empty,
    this.plans = const [],
    this.licenses = const [],
    this.usage = const [],
    this.audit = const [],
    this.billing = BillingOverview.empty,
    this.health = LicensingHealth.empty,
    this.settings = LicensingSettings.empty,
    this.selectedPlan,
    this.selectedOffice,
    this.planPreview,
    this.isBusy = false,
    this.actionError,
    this.actionMessage,
    this.featureSearch = '',
    this.licenseStatusFilter,
    this.auditFilters = const {},
  });

  final FeatureCatalog catalog;
  final List<LicensingPlan> plans;
  final List<OfficeLicenseRow> licenses;
  final List<OfficeUsageRow> usage;
  final List<LicenseAuditEntry> audit;
  final BillingOverview billing;
  final LicensingHealth health;
  final LicensingSettings settings;

  final PlanDetail? selectedPlan;
  final OfficeLicenseDetail? selectedOffice;

  /// The resolver run against a hypothetical office on [selectedPlan].
  final Map<String, dynamic>? planPreview;

  final bool isBusy;

  /// An action that failed. Deliberately separate from
  /// [PlatformLicensingError]: an action error must never replace the screen —
  /// the operator needs to still see what they were editing.
  final String? actionError;

  final String? actionMessage;

  final String featureSearch;
  final String? licenseStatusFilter;
  final Map<String, dynamic> auditFilters;

  bool get isEnforcing => settings.enforcementMode == 'enforcing';

  /// Search is the primary interaction on the catalog screen: at 47 features
  /// and growing, browsing is not the access pattern.
  List<CatalogFeature> get visibleFeatures {
    final q = featureSearch.trim().toLowerCase();
    final list = q.isEmpty
        ? catalog.features
        : catalog.features
              .where(
                (f) =>
                    f.key.toLowerCase().contains(q) ||
                    f.nameAr.contains(q) ||
                    f.nameEn.toLowerCase().contains(q) ||
                    f.categoryKey.toLowerCase().contains(q),
              )
              .toList();
    return list..sort((a, b) {
      final byCategory = a.categoryKey.compareTo(b.categoryKey);
      return byCategory != 0 ? byCategory : a.sortOrder.compareTo(b.sortOrder);
    });
  }

  List<OfficeLicenseRow> get visibleLicenses {
    final status = licenseStatusFilter;
    if (status == null) return licenses;
    return licenses.where((l) => l.status == status).toList();
  }

  int get overLimitOffices =>
      licenses.where((l) => l.overLimitCount > 0).length;
  int get delistedOffices => licenses.where((l) => l.isDelisted).length;

  PlatformLicensingLoaded copyWith({
    FeatureCatalog? catalog,
    List<LicensingPlan>? plans,
    List<OfficeLicenseRow>? licenses,
    List<OfficeUsageRow>? usage,
    List<LicenseAuditEntry>? audit,
    BillingOverview? billing,
    LicensingHealth? health,
    LicensingSettings? settings,
    PlanDetail? selectedPlan,
    bool clearSelectedPlan = false,
    OfficeLicenseDetail? selectedOffice,
    bool clearSelectedOffice = false,
    Map<String, dynamic>? planPreview,
    bool clearPlanPreview = false,
    bool? isBusy,
    String? actionError,
    String? actionMessage,
    String? featureSearch,
    String? licenseStatusFilter,
    bool clearLicenseStatusFilter = false,
    Map<String, dynamic>? auditFilters,
  }) {
    return PlatformLicensingLoaded(
      catalog: catalog ?? this.catalog,
      plans: plans ?? this.plans,
      licenses: licenses ?? this.licenses,
      usage: usage ?? this.usage,
      audit: audit ?? this.audit,
      billing: billing ?? this.billing,
      health: health ?? this.health,
      settings: settings ?? this.settings,
      selectedPlan: clearSelectedPlan
          ? null
          : (selectedPlan ?? this.selectedPlan),
      selectedOffice: clearSelectedOffice
          ? null
          : (selectedOffice ?? this.selectedOffice),
      planPreview: clearPlanPreview ? null : (planPreview ?? this.planPreview),
      isBusy: isBusy ?? this.isBusy,
      // Not carried forward: a message describes the action that just ran, so
      // re-emitting it on the next unrelated change would be a stale claim.
      actionError: actionError,
      actionMessage: actionMessage,
      featureSearch: featureSearch ?? this.featureSearch,
      licenseStatusFilter: clearLicenseStatusFilter
          ? null
          : (licenseStatusFilter ?? this.licenseStatusFilter),
      auditFilters: auditFilters ?? this.auditFilters,
    );
  }
}

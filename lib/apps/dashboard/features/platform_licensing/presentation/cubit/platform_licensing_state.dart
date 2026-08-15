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

/// One catalog category and the features of it that survived the filters.
typedef FeatureGroup = ({
  String key,
  String nameAr,
  List<CatalogFeature> features,
});

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
    this.featureCategoryFilter,
    this.featureEnforcementFilter,
    this.featureStatusFilter,
    this.selectedFeatureKey,
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

  /// The catalog's four narrowing axes. Search alone was the whole interaction
  /// and it only answers "where is the one I already know the name of" — these
  /// answer the questions the screen is actually opened with: what is in this
  /// category, what did we list but never build, what is switched off.
  final String? featureCategoryFilter;

  /// `enforced` | `declared`. The same split the KPI tiles count, so tapping a
  /// tile narrows the list to the rows it was counting.
  final String? featureEnforcementFilter;

  final String? featureStatusFilter;

  /// The row open in the detail pane. A key rather than the feature itself, so
  /// a catalog reload after a status change keeps the operator's place instead
  /// of pointing at a stale copy.
  final String? selectedFeatureKey;

  final String? licenseStatusFilter;
  final Map<String, dynamic> auditFilters;

  bool get isEnforcing => settings.enforcementMode == 'enforcing';

  /// Search is the primary interaction on the catalog screen: at 47 features
  /// and growing, browsing is not the access pattern.
  List<CatalogFeature> get visibleFeatures {
    final q = featureSearch.trim().toLowerCase();
    final list = catalog.features.where((f) {
      if (featureCategoryFilter != null &&
          f.categoryKey != featureCategoryFilter) {
        return false;
      }
      if (featureEnforcementFilter == 'enforced' && !f.isEnforced) return false;
      if (featureEnforcementFilter == 'declared' && f.isEnforced) return false;
      if (featureStatusFilter != null && f.status != featureStatusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return f.key.toLowerCase().contains(q) ||
          f.nameAr.contains(q) ||
          f.nameEn.toLowerCase().contains(q) ||
          f.categoryKey.toLowerCase().contains(q) ||
          f.descriptionAr.contains(q);
    }).toList();
    return list..sort((a, b) {
      final byCategory = a.categoryKey.compareTo(b.categoryKey);
      return byCategory != 0 ? byCategory : a.sortOrder.compareTo(b.sortOrder);
    });
  }

  /// [visibleFeatures] grouped by category, in the catalog's own order.
  ///
  /// Grouping is what removes the screen's biggest source of noise: in a flat
  /// list every row repeated its own category, four and five times running, in
  /// a column that was never labelled.
  List<FeatureGroup> get visibleFeatureGroups {
    final byCategory = <String, List<CatalogFeature>>{};
    for (final feature in visibleFeatures) {
      byCategory.putIfAbsent(feature.categoryKey, () => []).add(feature);
    }

    final groups = <FeatureGroup>[];
    for (final category in catalog.categories) {
      final rows = byCategory.remove(category.key);
      if (rows != null) {
        groups.add((
          key: category.key,
          nameAr: category.nameAr,
          features: rows,
        ));
      }
    }

    for (final key in byCategory.keys.toList()..sort()) {
      groups.add((
        key: key,
        nameAr: catalog.categoryName(key),
        features: byCategory[key]!,
      ));
    }
    return groups;
  }

  bool get hasFeatureFilters =>
      featureSearch.trim().isNotEmpty ||
      featureCategoryFilter != null ||
      featureEnforcementFilter != null ||
      featureStatusFilter != null;

  /// Spelled out, never counted: "٣ عوامل تصفية" makes the operator reopen the
  /// panel to find out which three, and a hidden filter is how a feature looks
  /// like it was deleted.
  List<String> get featureFilterLabels => [
    if (featureSearch.trim().isNotEmpty) 'بحث: «${featureSearch.trim()}»',
    if (featureCategoryFilter != null)
      catalog.categoryName(featureCategoryFilter!),
    if (featureEnforcementFilter == 'enforced') 'مطبَّقة بكود',
    if (featureEnforcementFilter == 'declared') 'معلنة فقط',
    if (featureStatusFilter != null)
      CatalogFeature.statusLabel(featureStatusFilter!),
  ];

  CatalogFeature? get selectedFeature {
    final key = selectedFeatureKey;
    if (key == null) return null;
    for (final feature in catalog.features) {
      if (feature.key == key) return feature;
    }
    return null;
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
    String? featureCategoryFilter,
    bool clearFeatureCategoryFilter = false,
    String? featureEnforcementFilter,
    bool clearFeatureEnforcementFilter = false,
    String? featureStatusFilter,
    bool clearFeatureStatusFilter = false,
    String? selectedFeatureKey,
    bool clearSelectedFeature = false,
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

      actionError: actionError,
      actionMessage: actionMessage,
      featureSearch: featureSearch ?? this.featureSearch,
      featureCategoryFilter: clearFeatureCategoryFilter
          ? null
          : (featureCategoryFilter ?? this.featureCategoryFilter),
      featureEnforcementFilter: clearFeatureEnforcementFilter
          ? null
          : (featureEnforcementFilter ?? this.featureEnforcementFilter),
      featureStatusFilter: clearFeatureStatusFilter
          ? null
          : (featureStatusFilter ?? this.featureStatusFilter),
      selectedFeatureKey: clearSelectedFeature
          ? null
          : (selectedFeatureKey ?? this.selectedFeatureKey),
      licenseStatusFilter: clearLicenseStatusFilter
          ? null
          : (licenseStatusFilter ?? this.licenseStatusFilter),
      auditFilters: auditFilters ?? this.auditFilters,
    );
  }
}

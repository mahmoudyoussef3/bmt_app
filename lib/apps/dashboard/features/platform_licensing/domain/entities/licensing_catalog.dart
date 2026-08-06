/// The catalog and plan side of the entitlement platform: what EWT *can* sell,
/// and the named bundles it sells it in.
///
/// Naming law (PLATFORM_LICENSING.md §1.2 F2): this domain says `plan`, never
/// `package`, and `license`, never `subscription`. Both of those words already
/// mean *passenger fare bundles* in four tables and one nav item, and a third
/// meaning would make them unreadable in SQL, in Dart and in every future
/// conversation about this system.
library;

/// Formats a raw jsonb feature value for display, and nothing else.
///
/// A limit is an integer or the literal string `unlimited` — never `-1` and
/// never null, because `-1` is a magic number arithmetic silently accepts and
/// null is indistinguishable from "no value stored at all", which is a
/// different rung of the resolution ladder.
class FeatureValue {
  const FeatureValue._();

  static const unlimited = 'unlimited';

  static bool isUnlimited(Object? value) => value == unlimited;

  static bool truthy(Object? value) => switch (value) {
    bool b => b,
    int i => i != 0,
    String s => s.isNotEmpty && s != 'false' && s != '0',
    _ => value != null,
  };

  static String label(Object? value, {String unit = ''}) {
    if (value == null) return '—';
    if (value is bool) return value ? 'مفعّلة' : 'غير مفعّلة';
    if (isUnlimited(value)) return 'بلا حدود';
    if (value is num) return unit.isEmpty ? '$value' : '$value $unit';
    return '$value';
  }
}

class FeatureCategory {
  const FeatureCategory({
    required this.key,
    required this.nameAr,
    this.sortOrder = 100,
  });

  final String key;
  final String nameAr;
  final int sortOrder;

  factory FeatureCategory.fromJson(Map<String, dynamic> json) =>
      FeatureCategory(
        key: json['key'] as String,
        nameAr: (json['name_ar'] as String?) ?? (json['key'] as String),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 100,
      );
}

/// Where a feature is actually enforced. Real data, not a doc comment: the
/// migration that creates a gate inserts the row, and a trigger derives
/// [CatalogFeature.isEnforced] from it — so the console's badge can never claim
/// more than the code delivers.
class FeatureGate {
  const FeatureGate({required this.kind, required this.ref, this.note = ''});

  final String kind; // trigger | rpc | rls | view | ui
  final String ref;
  final String note;

  String get kindLabelAr => switch (kind) {
    'trigger' => 'مُشغِّل قاعدة بيانات',
    'rpc' => 'دالة خادم',
    'rls' => 'سياسة وصول',
    'view' => 'عرض',
    'ui' => 'واجهة',
    _ => kind,
  };

  factory FeatureGate.fromJson(Map<String, dynamic> json) => FeatureGate(
    kind: (json['gate_kind'] as String?) ?? '',
    ref: (json['gate_ref'] as String?) ?? '',
    note: (json['note'] as String?) ?? '',
  );
}

/// One catalogued capability.
class CatalogFeature {
  const CatalogFeature({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.categoryKey,
    required this.valueType,
    required this.defaultValue,
    required this.status,
    required this.isEnforced,
    this.descriptionAr = '',
    this.unitAr = '',
    this.isPublic = true,
    this.meterKind,
    this.meterPeriod,
    this.allowedValues = const [],
    this.gates = const [],
    this.requires = const [],
    this.requiredBy = const [],
    this.planCount = 0,
    this.overrideCount = 0,
    this.impact = const {},
    this.sortOrder = 100,
  });

  final String key;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String categoryKey;

  /// `boolean` | `limit` | `enum` | `config`.
  final String valueType;

  final Object? defaultValue;

  /// `active` | `hidden` | `deprecated` | `disabled`. `disabled` is the
  /// platform-wide kill switch: the feature resolves to its default for
  /// everyone, whatever any plan or override says.
  final String status;

  /// True when at least one [FeatureGate] exists. A `declared` feature is
  /// catalogued and sellable in principle but has no code behind it yet, and
  /// the plan builder marks it so nobody promises a customer something the
  /// code does not do.
  final bool isEnforced;

  final String unitAr;
  final bool isPublic;

  /// `stock` (a COUNT of live rows — deleting one returns quota) or `flow` (an
  /// accumulating counter — deleting does NOT refund). Null for non-limits.
  final String? meterKind;
  final String? meterPeriod;

  final List<String> allowedValues;
  final List<FeatureGate> gates;
  final List<String> requires;
  final List<String> requiredBy;
  final int planCount;
  final int overrideCount;

  /// How many offices currently resolve to each value.
  final Map<String, int> impact;

  final int sortOrder;

  bool get isKillSwitched => status == 'disabled';
  bool get isLimit => valueType == 'limit';
  bool get isStock => meterKind == 'stock';

  String get statusLabelAr => switch (status) {
    'active' => 'نشطة',
    'hidden' => 'مخفية',
    'deprecated' => 'مهجورة',
    'disabled' => 'موقوفة على مستوى المنصة',
    _ => status,
  };

  String get valueTypeLabelAr => switch (valueType) {
    'boolean' => 'تشغيل/إيقاف',
    'limit' => 'حد رقمي',
    'enum' => 'مستوى',
    'config' => 'إعداد',
    _ => valueType,
  };

  factory CatalogFeature.fromJson(Map<String, dynamic> json) {
    final schema = (json['value_schema'] as Map?) ?? const {};
    return CatalogFeature(
      key: json['key'] as String,
      nameAr: (json['name_ar'] as String?) ?? (json['key'] as String),
      nameEn: (json['name_en'] as String?) ?? '',
      descriptionAr: (json['description_ar'] as String?) ?? '',
      categoryKey: (json['category_key'] as String?) ?? '',
      valueType: (json['value_type'] as String?) ?? 'boolean',
      defaultValue: json['default_value'],
      status: (json['status'] as String?) ?? 'active',
      isEnforced: json['enforcement_status'] == 'enforced',
      unitAr: (json['unit_ar'] as String?) ?? '',
      isPublic: json['is_public'] != false,
      meterKind: json['meter_kind'] as String?,
      meterPeriod: json['meter_period'] as String?,
      allowedValues: [
        for (final v in (schema['allowed'] as List?) ?? const []) '$v',
      ],
      gates: [
        for (final g in (json['gates'] as List?) ?? const [])
          FeatureGate.fromJson(Map<String, dynamic>.from(g as Map)),
      ],
      requires: [
        for (final d in (json['requires'] as List?) ?? const [])
          (d as Map)['key'] as String,
      ],
      requiredBy: [
        for (final d in (json['required_by'] as List?) ?? const []) '$d',
      ],
      planCount: (json['plan_count'] as num?)?.toInt() ?? 0,
      overrideCount: (json['override_count'] as num?)?.toInt() ?? 0,
      impact: {
        for (final e in ((json['impact'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as num).toInt(),
      },
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 100,
    );
  }
}

class FeatureCatalog {
  const FeatureCatalog({required this.categories, required this.features});

  final List<FeatureCategory> categories;
  final List<CatalogFeature> features;

  static const empty = FeatureCatalog(categories: [], features: []);

  int get enforcedCount => features.where((f) => f.isEnforced).length;
  int get declaredCount => features.length - enforcedCount;

  String categoryName(String key) => categories
      .firstWhere(
        (c) => c.key == key,
        orElse: () => FeatureCategory(key: key, nameAr: key),
      )
      .nameAr;

  factory FeatureCatalog.fromJson(Map<String, dynamic> json) => FeatureCatalog(
    categories: [
      for (final c in (json['categories'] as List?) ?? const [])
        FeatureCategory.fromJson(Map<String, dynamic>.from(c as Map)),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    features: [
      for (final f in (json['features'] as List?) ?? const [])
        CatalogFeature.fromJson(Map<String, dynamic>.from(f as Map)),
    ],
  );
}

/// A named bundle of default feature values.
///
/// **A plan is a template with no behaviour.** It cannot contain logic,
/// conditions or code; anything a plan "does" is a value the resolver reads.
/// That is exactly what makes plans safe to edit live — and edits DO propagate
/// immediately, because the resolver reads plan values at resolution time and
/// there is no per-office copy to keep in sync.
class LicensingPlan {
  const LicensingPlan({
    required this.id,
    required this.key,
    required this.nameAr,
    required this.status,
    this.nameEn = '',
    this.taglineAr = '',
    this.isPublic = false,
    this.priceMonthly,
    this.priceYearly,
    this.currency = 'EGP',
    this.trialDays = 0,
    this.downgradeToKey,
    this.officeCount = 0,
    this.featureCount = 0,
    this.revision = 0,
    this.notes = '',
    this.sortOrder = 100,
  });

  final String id;
  final String key;
  final String nameAr;
  final String nameEn;
  final String taglineAr;

  /// `draft` | `active` | `archived`. Archiving keeps existing licenses
  /// resolving and only stops new offices selecting it.
  final String status;

  final bool isPublic;
  final num? priceMonthly;
  final num? priceYearly;
  final String currency;
  final int trialDays;
  final String? downgradeToKey;
  final int officeCount;
  final int featureCount;
  final int revision;
  final String notes;
  final int sortOrder;

  bool get isArchived => status == 'archived';

  String get statusLabelAr => switch (status) {
    'draft' => 'مسودة',
    'active' => 'نشطة',
    'archived' => 'مؤرشفة',
    _ => status,
  };

  factory LicensingPlan.fromJson(Map<String, dynamic> json) => LicensingPlan(
    id: json['id'] as String,
    key: json['key'] as String,
    nameAr: (json['name_ar'] as String?) ?? (json['key'] as String),
    nameEn: (json['name_en'] as String?) ?? '',
    taglineAr: (json['tagline_ar'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'draft',
    isPublic: json['is_public'] == true,
    priceMonthly: json['price_monthly'] as num?,
    priceYearly: json['price_yearly'] as num?,
    currency: (json['currency'] as String?) ?? 'EGP',
    trialDays: (json['trial_days'] as num?)?.toInt() ?? 0,
    downgradeToKey: json['downgrade_to_key'] as String?,
    officeCount: (json['office_count'] as num?)?.toInt() ?? 0,
    featureCount: (json['feature_count'] as num?)?.toInt() ?? 0,
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    notes: (json['notes'] as String?) ?? '',
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 100,
  );
}

class PlanRevision {
  const PlanRevision({
    required this.id,
    required this.revision,
    required this.createdAt,
    this.reason = '',
    this.snapshot = const {},
  });

  final String id;
  final int revision;
  final DateTime createdAt;
  final String reason;
  final Map<String, dynamic> snapshot;

  /// The feature map as it stood before the edit this revision records.
  Map<String, dynamic> get features =>
      Map<String, dynamic>.from((snapshot['features'] as Map?) ?? const {});

  factory PlanRevision.fromJson(Map<String, dynamic> json) => PlanRevision(
    id: json['id'] as String,
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.now(),
    reason: (json['reason'] as String?) ?? '',
    snapshot: Map<String, dynamic>.from((json['snapshot'] as Map?) ?? const {}),
  );
}

class PlanOfficeRef {
  const PlanOfficeRef({
    required this.officeId,
    required this.name,
    required this.status,
  });

  final String officeId;
  final String name;
  final String status;

  factory PlanOfficeRef.fromJson(Map<String, dynamic> json) => PlanOfficeRef(
    officeId: json['office_id'] as String,
    name: (json['name'] as String?) ?? '',
    status: (json['status'] as String?) ?? '',
  );
}

class PlanDetail {
  const PlanDetail({
    required this.plan,
    required this.values,
    this.offices = const [],
    this.revisions = const [],
  });

  final LicensingPlan plan;

  /// feature key → value. A key that is ABSENT means "fall through to the
  /// catalog default", which is a different statement from setting it false.
  final Map<String, Object?> values;

  final List<PlanOfficeRef> offices;
  final List<PlanRevision> revisions;

  factory PlanDetail.fromJson(Map<String, dynamic> json) => PlanDetail(
    plan: LicensingPlan.fromJson(
      Map<String, dynamic>.from(json['plan'] as Map),
    ),
    values: Map<String, Object?>.from((json['features'] as Map?) ?? const {}),
    offices: [
      for (final o in (json['offices'] as List?) ?? const [])
        PlanOfficeRef.fromJson(Map<String, dynamic>.from(o as Map)),
    ],
    revisions: [
      for (final r in (json['revisions'] as List?) ?? const [])
        PlanRevision.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
  );
}

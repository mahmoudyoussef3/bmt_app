import '../../../../core/entitlements/entitlement_context.dart';

import 'licensing_catalog.dart';

/// The tenant side of the entitlement platform: one office's commercial state,
/// its exceptions, its usage, its invoices and the decisions made about it.

/// A row in the التراخيص list.
class OfficeLicenseRow {
  const OfficeLicenseRow({
    required this.officeId,
    required this.officeName,
    required this.status,
    this.officeSlug = '',
    this.listingStatus = '',
    this.licensingHold = 'none',
    this.planKey = '',
    this.planNameAr = '',
    this.billingCycle,
    this.price,
    this.currency = 'EGP',
    this.trialEndsAt,
    this.periodEnd,
    this.autoRenew = false,
    this.overrideCount = 0,
    this.overLimitCount = 0,
  });

  final String officeId;
  final String officeName;
  final String officeSlug;
  final String listingStatus;

  /// `none` | `read_only` | `delisted` — the denormalised consequence of
  /// [status], and the only licensing term `office_is_listed()` reads.
  final String licensingHold;

  final String planKey;
  final String planNameAr;
  final String status;
  final String? billingCycle;
  final num? price;
  final String currency;
  final DateTime? trialEndsAt;
  final DateTime? periodEnd;
  final bool autoRenew;
  final int overrideCount;

  /// How many limits this office is currently over.
  ///
  /// A real, legitimate state and not an error: limits gate creation, never
  /// existence, so an office that downgraded keeps every row it had and simply
  /// cannot add more. Showing the number honestly beats pretending compliance.
  final int overLimitCount;

  bool get isDelisted => licensingHold == 'delisted';
  bool get hasLicense => status != 'none';

  String get statusLabelAr => switch (status) {
    'trialing' => 'فترة تجريبية',
    'active' => 'نشطة',
    'past_due' => 'متأخرة السداد',
    'grace' => 'مهلة أخيرة',
    'suspended' => 'موقوفة',
    'cancelled' => 'ملغاة',
    'expired' => 'منتهية',
    _ => 'بدون ترخيص',
  };

  factory OfficeLicenseRow.fromJson(Map<String, dynamic> json) {
    DateTime? at(String k) => DateTime.tryParse((json[k] as String?) ?? '');
    return OfficeLicenseRow(
      officeId: json['office_id'] as String,
      officeName: (json['office_name'] as String?) ?? '',
      officeSlug: (json['office_slug'] as String?) ?? '',
      listingStatus: (json['listing_status'] as String?) ?? '',
      licensingHold: (json['licensing_hold'] as String?) ?? 'none',
      planKey: (json['plan_key'] as String?) ?? '',
      planNameAr: (json['plan_name_ar'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'none',
      billingCycle: json['billing_cycle'] as String?,
      price: json['price'] as num?,
      currency: (json['currency'] as String?) ?? 'EGP',
      trialEndsAt: at('trial_ends_at'),
      periodEnd: at('period_end'),
      autoRenew: json['auto_renew'] == true,
      overrideCount: (json['override_count'] as num?)?.toInt() ?? 0,
      overLimitCount: (json['over_limit'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A per-office, per-feature exception.
///
/// Overrides both GRANT and REVOKE — the brief's own example is disabling API
/// access on an Enterprise contract — so [isUpgrade] reads the direction from
/// the plan value rather than assuming one.
class FeatureOverride {
  const FeatureOverride({
    required this.featureKey,
    required this.nameAr,
    required this.value,
    required this.reason,
    this.categoryKey = '',
    this.valueType = 'boolean',
    this.planValue,
    this.expiresAt,
    this.expired = false,
    this.createdAt,
  });

  final String featureKey;
  final String nameAr;
  final String categoryKey;
  final String valueType;
  final Object? value;

  /// What the office's plan would have resolved to. The direction the console
  /// renders as ▲ upgrade / ▼ restriction.
  final Object? planValue;

  /// Never empty: the table's own CHECK requires at least eight characters. An
  /// override with no stated reason becomes a permanent unexplained exception,
  /// because in two years nobody dares remove it.
  final String reason;

  final DateTime? expiresAt;

  /// An expired override stops applying but is NOT deleted — the row is the
  /// record that the concession happened.
  final bool expired;

  final DateTime? createdAt;

  bool? get isUpgrade {
    if (planValue == null) return null;
    if (value is bool && planValue is bool) {
      return (value as bool) && !(planValue as bool);
    }
    if (FeatureValue.isUnlimited(value)) {
      return !FeatureValue.isUnlimited(planValue);
    }
    if (FeatureValue.isUnlimited(planValue)) return false;
    if (value is num && planValue is num) {
      return (value as num) > (planValue as num);
    }
    return null;
  }

  factory FeatureOverride.fromJson(Map<String, dynamic> json) =>
      FeatureOverride(
        featureKey: json['feature_key'] as String,
        nameAr: (json['name_ar'] as String?) ?? (json['feature_key'] as String),
        categoryKey: (json['category_key'] as String?) ?? '',
        valueType: (json['value_type'] as String?) ?? 'boolean',
        value: json['value'],
        planValue: json['plan_value'],
        reason: (json['reason'] as String?) ?? '',
        expiresAt: DateTime.tryParse((json['expires_at'] as String?) ?? ''),
        expired: json['expired'] == true,
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      );
}

class PlatformInvoice {
  const PlatformInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.total,
    required this.status,
    this.officeId,
    this.officeName,
    this.currency = 'EGP',
    this.periodStart,
    this.periodEnd,
    this.issuedAt,
    this.dueAt,
    this.paidAt,
    this.paymentMethod,
    this.lineItems = const [],
  });

  final String id;
  final String invoiceNumber;
  final String? officeId;
  final String? officeName;
  final num total;
  final String currency;

  /// `draft` | `issued` | `paid` | `overdue` | `void` | `refunded`.
  final String status;

  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final String? paymentMethod;

  /// Open-ended by design: add-ons, overage, proration and coupons all land
  /// here as items rather than as columns.
  final List<Map<String, dynamic>> lineItems;

  bool get isPayable => const {'issued', 'overdue', 'draft'}.contains(status);
  bool get isPaid => status == 'paid';

  String get statusLabelAr => switch (status) {
    'draft' => 'مسودة',
    'issued' => 'صادرة',
    'paid' => 'مسددة',
    'overdue' => 'متأخرة',
    'void' => 'ملغاة',
    'refunded' => 'مستردة',
    _ => status,
  };

  factory PlatformInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? at(String k) => DateTime.tryParse((json[k] as String?) ?? '');
    return PlatformInvoice(
      id: json['id'] as String,
      invoiceNumber: (json['invoice_number'] as String?) ?? '',
      officeId: json['office_id'] as String?,
      officeName: json['office_name'] as String?,
      total: (json['total'] as num?) ?? 0,
      currency: (json['currency'] as String?) ?? 'EGP',
      status: (json['status'] as String?) ?? 'draft',
      periodStart: at('period_start'),
      periodEnd: at('period_end'),
      issuedAt: at('issued_at'),
      dueAt: at('due_at'),
      paidAt: at('paid_at'),
      paymentMethod: json['payment_method'] as String?,
      lineItems: [
        for (final i in (json['line_items'] as List?) ?? const [])
          Map<String, dynamic>.from(i as Map),
      ],
    );
  }
}

/// One entry in the licensing decision trail.
class LicenseAuditEntry {
  const LicenseAuditEntry({
    required this.id,
    required this.entityType,
    required this.entityRef,
    required this.action,
    required this.createdAt,
    this.officeName,
    this.actorLabel = '',
    this.reason = '',
    this.oldValue,
    this.newValue,
  });

  final int id;
  final String entityType;
  final String entityRef;
  final String action;
  final DateTime createdAt;
  final String? officeName;

  /// Denormalised on write, so the trail still reads correctly after the actor
  /// is removed.
  final String actorLabel;

  final String reason;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;

  String get actionLabelAr => switch (action) {
    'created' => 'إنشاء',
    'updated' => 'تعديل',
    'deleted' => 'حذف',
    'enabled' => 'تفعيل',
    'disabled' => 'إيقاف',
    'plan_changed' => 'تغيير باقة',
    'limit_changed' => 'تغيير حد',
    'override_created' => 'استثناء جديد',
    'override_removed' => 'إزالة استثناء',
    'trial_started' => 'بدء تجربة',
    'trial_extended' => 'تمديد تجربة',
    'renewed' => 'تجديد/سداد',
    'suspended' => 'إيقاف',
    'restored' => 'استئناف',
    'cancelled' => 'إلغاء',
    _ => action,
  };

  String get entityLabelAr => switch (entityType) {
    'feature' => 'ميزة',
    'category' => 'تصنيف',
    'plan' => 'باقة',
    'plan_feature' => 'قيمة باقة',
    'license' => 'ترخيص',
    'override' => 'استثناء',
    'invoice' => 'فاتورة',
    'usage' => 'استهلاك',
    'settings' => 'إعدادات',
    _ => entityType,
  };

  factory LicenseAuditEntry.fromJson(Map<String, dynamic> json) =>
      LicenseAuditEntry(
        id: (json['id'] as num).toInt(),
        entityType: (json['entity_type'] as String?) ?? '',
        entityRef: (json['entity_ref'] as String?) ?? '',
        action: (json['action'] as String?) ?? '',
        createdAt:
            DateTime.tryParse((json['created_at'] as String?) ?? '') ??
            DateTime.now(),
        officeName: json['office_name'] as String?,
        actorLabel: (json['actor_label'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? '',
        oldValue: json['old_value'] == null
            ? null
            : Map<String, dynamic>.from(json['old_value'] as Map),
        newValue: json['new_value'] == null
            ? null
            : Map<String, dynamic>.from(json['new_value'] as Map),
      );
}

/// Everything the platform admin needs about one office, in one payload.
class OfficeLicenseDetail {
  const OfficeLicenseDetail({
    required this.officeId,
    required this.officeName,
    required this.entitlements,
    this.licensingHold = 'none',
    this.listingStatus = '',
    this.overrides = const [],
    this.invoices = const [],
    this.activity = const [],
  });

  final String officeId;
  final String officeName;
  final String licensingHold;
  final String listingStatus;

  /// The office's resolved document, produced by the same resolver the office
  /// itself reads — so the console and the tenant can never disagree.
  final EntitlementContext entitlements;

  final List<FeatureOverride> overrides;
  final List<PlatformInvoice> invoices;
  final List<LicenseAuditEntry> activity;

  LicenseSummary get license => entitlements.license;

  /// Limits the office is currently over. Shown, never silently corrected —
  /// resolving an over-limit by deleting a tenant's operational data is not
  /// something the platform gets to do.
  List<ResolvedFeature> get overLimits =>
      entitlements.limits.where((f) => f.isOverLimit).toList();

  factory OfficeLicenseDetail.fromJson(Map<String, dynamic> json) {
    final office = Map<String, dynamic>.from(
      (json['office'] as Map?) ?? const {},
    );
    return OfficeLicenseDetail(
      officeId: (office['id'] as String?) ?? '',
      officeName: (office['name'] as String?) ?? '',
      licensingHold: (office['licensing_hold'] as String?) ?? 'none',
      listingStatus: (office['listing_status'] as String?) ?? '',
      entitlements: EntitlementContext.fromRpc(
        Map<String, dynamic>.from((json['entitlements'] as Map?) ?? const {}),
      ),
      overrides: [
        for (final o in (json['overrides'] as List?) ?? const [])
          FeatureOverride.fromJson(Map<String, dynamic>.from(o as Map)),
      ],
      invoices: [
        for (final i in (json['invoices'] as List?) ?? const [])
          PlatformInvoice.fromJson(Map<String, dynamic>.from(i as Map)),
      ],
      activity: [
        for (final a in (json['activity'] as List?) ?? const [])
          LicenseAuditEntry.fromJson(Map<String, dynamic>.from(a as Map)),
      ],
    );
  }
}

class UsageMetric {
  const UsageMetric({
    required this.key,
    required this.nameAr,
    required this.used,
    this.limit,
    this.unitAr = '',
    this.meterKind,
  });

  final String key;
  final String nameAr;
  final int used;

  /// Null means unlimited.
  final int? limit;

  final String unitAr;
  final String? meterKind;

  bool get isUnlimited => limit == null;
  bool get isOver => limit != null && used > limit!;
  double get ratio => limit == null || limit == 0
      ? 0
      : (used / limit!).clamp(0.0, 1.0).toDouble();

  factory UsageMetric.fromJson(Map<String, dynamic> json) {
    final raw = json['limit'];
    return UsageMetric(
      key: json['key'] as String,
      nameAr: (json['name_ar'] as String?) ?? (json['key'] as String),
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: raw is num ? raw.toInt() : null,
      unitAr: (json['unit_ar'] as String?) ?? '',
      meterKind: json['meter_kind'] as String?,
    );
  }
}

class OfficeUsageRow {
  const OfficeUsageRow({
    required this.officeId,
    required this.officeName,
    this.planKey = '',
    this.metrics = const [],
  });

  final String officeId;
  final String officeName;
  final String planKey;
  final List<UsageMetric> metrics;

  List<UsageMetric> get overLimits => metrics.where((m) => m.isOver).toList();

  factory OfficeUsageRow.fromJson(Map<String, dynamic> json) => OfficeUsageRow(
    officeId: json['office_id'] as String,
    officeName: (json['office_name'] as String?) ?? '',
    planKey: (json['plan_key'] as String?) ?? '',
    metrics: [
      for (final m in (json['metrics'] as List?) ?? const [])
        UsageMetric.fromJson(Map<String, dynamic>.from(m as Map)),
    ],
  );
}

/// What actually gets opened daily.
class LicensingHealth {
  const LicensingHealth({
    this.enforcementMode = 'off',
    this.trialsEnding = const [],
    this.pastDue = const [],
    this.overLimit = const [],
    this.soldButDeclared = const [],
    this.overridesExpiring = const [],
    this.officesWithoutLicense = const [],
  });

  final String enforcementMode;
  final List<Map<String, dynamic>> trialsEnding;
  final List<Map<String, dynamic>> pastDue;
  final List<Map<String, dynamic>> overLimit;

  /// A `declared` feature switched on by an active plan — a promise the code
  /// does not keep. Surfaced rather than tolerated: shipping flags that
  /// silently do nothing is how a licensing system loses credibility.
  final List<Map<String, dynamic>> soldButDeclared;

  final List<Map<String, dynamic>> overridesExpiring;
  final List<Map<String, dynamic>> officesWithoutLicense;

  static const empty = LicensingHealth();

  bool get isClean =>
      trialsEnding.isEmpty &&
      pastDue.isEmpty &&
      overLimit.isEmpty &&
      soldButDeclared.isEmpty &&
      overridesExpiring.isEmpty &&
      officesWithoutLicense.isEmpty;

  factory LicensingHealth.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String k) => [
      for (final e in (json[k] as List?) ?? const [])
        Map<String, dynamic>.from(e as Map),
    ];
    return LicensingHealth(
      enforcementMode: (json['enforcement_mode'] as String?) ?? 'off',
      trialsEnding: list('trials_ending'),
      pastDue: list('past_due'),
      overLimit: list('over_limit'),
      soldButDeclared: list('sold_but_declared'),
      overridesExpiring: list('overrides_expiring'),
      officesWithoutLicense: list('offices_without_license'),
    );
  }
}

/// The platform's own settings row — including the kill switch.
class LicensingSettings {
  const LicensingSettings({
    this.enforcementMode = 'off',
    this.restrictedPlanKey,
    this.defaultSignupPlanKey,
    this.graceDays = 7,
    this.warnDaysBefore = 7,
  });

  /// `off` | `shadow` | `enforcing`.
  ///
  /// Moving between them is a one-row UPDATE: `off` restores pre-licensing
  /// behaviour instantly, with no deploy.
  final String enforcementMode;

  final String? restrictedPlanKey;
  final String? defaultSignupPlanKey;
  final int graceDays;
  final int warnDaysBefore;

  static const empty = LicensingSettings();

  String get modeLabelAr => switch (enforcementMode) {
    'off' => 'معطّل — لا يُطبَّق أي حد',
    'shadow' => 'وضع الظل — يُسجَّل ولا يُمنع',
    'enforcing' => 'مفعّل — تُطبَّق الحدود',
    _ => enforcementMode,
  };

  factory LicensingSettings.fromJson(Map<String, dynamic> json) =>
      LicensingSettings(
        enforcementMode: (json['enforcement_mode'] as String?) ?? 'off',
        restrictedPlanKey: json['restricted_plan_key'] as String?,
        defaultSignupPlanKey: json['default_signup_plan_key'] as String?,
        graceDays: (json['grace_days'] as num?)?.toInt() ?? 7,
        warnDaysBefore: (json['warn_days_before'] as num?)?.toInt() ?? 7,
      );
}

class BillingOverview {
  const BillingOverview({
    this.issued = 0,
    this.paid = 0,
    this.overdue = 0,
    this.invoiceCount = 0,
    this.mrr = 0,
    this.invoices = const [],
    this.renewals = const [],
  });

  final num issued;
  final num paid;
  final num overdue;
  final int invoiceCount;

  /// Monthly recurring revenue at list, from ACTIVE licenses only — trials and
  /// held offices are excluded because neither is billing anybody today.
  final num mrr;

  final List<PlatformInvoice> invoices;
  final List<Map<String, dynamic>> renewals;

  static const empty = BillingOverview();

  factory BillingOverview.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, dynamic>.from(
      (json['totals'] as Map?) ?? const {},
    );
    return BillingOverview(
      issued: (totals['issued'] as num?) ?? 0,
      paid: (totals['paid'] as num?) ?? 0,
      overdue: (totals['overdue'] as num?) ?? 0,
      invoiceCount: (totals['count'] as num?)?.toInt() ?? 0,
      mrr: (json['mrr'] as num?) ?? 0,
      invoices: [
        for (final i in (json['invoices'] as List?) ?? const [])
          PlatformInvoice.fromJson(Map<String, dynamic>.from(i as Map)),
      ],
      renewals: [
        for (final r in (json['renewals'] as List?) ?? const [])
          Map<String, dynamic>.from(r as Map),
      ],
    );
  }
}

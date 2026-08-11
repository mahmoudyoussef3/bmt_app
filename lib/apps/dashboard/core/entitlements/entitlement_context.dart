/// What the signed-in office bought, resolved once at sign-in.
///
/// The parallel of [OfficeContext] on the third axis of the composition law:
///
///     may = role_permits ∧ office_entitled ∧ quota_allows
///
/// Three predicates, ANDed, never merged. This file owns the middle one — and it
/// is deliberately *not* folded into `DashboardPermissions`, because a merged
/// system can never answer "why can't I do this?", which is the one question a
/// licensing UI must always be able to answer.
///
/// **A hint for the shell, nothing more.** Inherited verbatim from
/// [OfficeContext.isPlatformAdmin]'s doctrine: every write this enables is
/// re-checked server-side by a trigger or an `assert_feature()` guard, so a
/// forged `true` here reaches a screen whose every action is refused.
library;

/// The keys this app actually reads. The catalog holds 47; a Dart constant is
/// only warranted where code branches on one.
///
/// Not an enum: the catalog is data and can grow without a deploy, so a closed
/// Dart type would be a lie about the system's own extensibility.
class FeatureKeys {
  const FeatureKeys._();

  static const trips = 'trips';
  static const routes = 'routes';
  static const liveTracking = 'live_tracking';
  static const liveOpsCenter = 'live_ops_center';
  static const drivers = 'drivers';
  static const driverApp = 'driver_app';
  static const bookings = 'bookings';
  static const passengerPackages = 'passenger_packages';
  static const finance = 'finance';
  static const wallet = 'wallet';
  static const refunds = 'refunds';
  static const cashback = 'cashback';
  static const referrals = 'referrals';
  static const reports = 'reports';
  static const reportLevel = 'report_level';
  static const analyticsLevel = 'analytics_level';
  static const exportPdf = 'export_pdf';
  static const exportExcel = 'export_excel';
  static const notifications = 'notifications';
  static const supportTickets = 'support_tickets';
  static const logoMaxKb = 'logo_max_kb';
  static const maxDrivers = 'max_drivers';
  static const maxVehicles = 'max_vehicles';
  static const maxRoutes = 'max_routes';
  static const maxAdminUsers = 'max_admin_users';
  static const maxTripsPerMonth = 'max_trips_per_month';
}

/// One feature, as the resolver answered it.
class ResolvedFeature {
  const ResolvedFeature({
    required this.key,
    required this.value,
    required this.valueType,
    required this.source,
    this.nameAr = '',
    this.categoryKey = '',
    this.unitAr = '',
    this.blockedBy,
    this.expiresAt,
    this.used,
    this.remaining,
    this.isPublic = true,
    this.enforced = false,
    this.sortOrder = 100,
  });

  final String key;

  /// `bool`, `int`, or `String` — including the literal `'unlimited'`.
  ///
  /// Never `-1` and never null: a limit is a non-negative integer or the string
  /// `'unlimited'`, enforced by the catalog's own validation. `-1` is a magic
  /// number arithmetic silently accepts, and `null` is indistinguishable from
  /// "no row", which is a different rung of the resolution ladder.
  final Object? value;

  /// `boolean` | `limit` | `enum` | `config`.
  final String valueType;

  /// Which rung answered: `kill_switch` | `license_hold` | `override` | `plan` |
  /// `default`. Not decoration — it is what lets a screen say *why*.
  final String source;

  /// Set when a prerequisite defeated the value at the dependency gate. The
  /// override is still reported in [source]; both facts are true at once, and
  /// showing only one of them looks like the system ignored the operator.
  final String? blockedBy;

  final String nameAr;
  final String categoryKey;
  final String unitAr;
  final DateTime? expiresAt;

  /// Present for `limit` features only.
  final int? used;
  final int? remaining;

  /// Could the office buy this on a higher plan? Decides hidden-vs-locked:
  /// hiding a purchasable feature makes it unsellable, showing an unpurchasable
  /// one is noise.
  final bool isPublic;

  /// Whether any code actually gates this. A `declared` feature is catalogued
  /// and sellable in principle but does nothing yet, and must never be presented
  /// to an office as something they are about to gain.
  final bool enforced;

  final int sortOrder;

  bool get isOn => _truthy(value);

  bool get isUnlimited => value == 'unlimited';

  /// The numeric ceiling, or null when unlimited or not a limit at all.
  int? get limit => value is int ? value as int : null;

  bool get isOverLimit {
    final l = limit;
    final u = used;
    return l != null && u != null && u > l;
  }

  static bool _truthy(Object? v) => switch (v) {
    bool b => b,
    int i => i != 0,
    String s => s.isNotEmpty && s != 'false' && s != '0',
    _ => v != null,
  };

  factory ResolvedFeature.fromJson(String key, Map<String, dynamic> json) {
    return ResolvedFeature(
      key: key,
      value: json['value'],
      valueType: (json['value_type'] as String?) ?? 'boolean',
      source: (json['source'] as String?) ?? 'default',
      blockedBy: json['blocked_by'] as String?,
      nameAr: (json['name_ar'] as String?) ?? key,
      categoryKey: (json['category_key'] as String?) ?? '',
      unitAr: (json['unit_ar'] as String?) ?? '',
      expiresAt: DateTime.tryParse((json['expires_at'] as String?) ?? ''),
      used: (json['used'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      isPublic: json['is_public'] != false,
      enforced: json['enforcement_status'] == 'enforced',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 100,
    );
  }
}

/// The office's commercial state, for the banner and the billing screen.
class LicenseSummary {
  const LicenseSummary({
    required this.planKey,
    required this.planNameAr,
    required this.status,
    this.billingCycle,
    this.price,
    this.currency = 'EGP',
    this.trialEndsAt,
    this.periodStart,
    this.periodEnd,
    this.graceEndsAt,
    this.autoRenew = false,
    this.contractRef,
    this.suspendedReason,
  });

  final String planKey;
  final String planNameAr;

  /// `trialing` | `active` | `past_due` | `grace` | `suspended` | `cancelled` |
  /// `expired`, or `none` for an office with no license row yet.
  final String status;

  final String? billingCycle;
  final num? price;
  final String currency;
  final DateTime? trialEndsAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? graceEndsAt;
  final bool autoRenew;
  final String? contractRef;
  final String? suspendedReason;

  bool get isTrialing => status == 'trialing';

  /// Does the office owe the platform something, or has it been held? Drives the
  /// billing banner. Note `past_due` and `grace` are fully operational states —
  /// what they need is a banner, not a block.
  bool get needsAttention => const {
    'past_due',
    'grace',
    'suspended',
    'cancelled',
    'expired',
  }.contains(status);

  bool get isHeld =>
      const {'suspended', 'cancelled', 'expired'}.contains(status);

  String get statusLabelAr => switch (status) {
    'trialing' => 'فترة تجريبية',
    'active' => 'نشطة',
    'past_due' => 'فاتورة متأخرة',
    'grace' => 'مهلة أخيرة',
    'suspended' => 'موقوفة',
    'cancelled' => 'ملغاة',
    'expired' => 'منتهية',
    _ => 'بدون ترخيص',
  };

  /// Days left in the trial, negative once it has passed. Null when not trialing.
  int? get trialDaysLeft {
    final end = trialEndsAt;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  factory LicenseSummary.fromJson(Map<String, dynamic> json) {
    DateTime? at(String k) => DateTime.tryParse((json[k] as String?) ?? '');
    return LicenseSummary(
      planKey: (json['plan_key'] as String?) ?? '',
      planNameAr: (json['plan_name_ar'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'none',
      billingCycle: json['billing_cycle'] as String?,
      price: json['price'] as num?,
      currency: (json['currency'] as String?) ?? 'EGP',
      trialEndsAt: at('trial_ends_at'),
      periodStart: at('period_start'),
      periodEnd: at('period_end'),
      graceEndsAt: at('grace_ends_at'),
      autoRenew: json['auto_renew'] == true,
      contractRef: json['contract_ref'] as String?,
      suspendedReason: json['suspended_reason'] as String?,
    );
  }
}

/// The resolved entitlement document, held for the lifetime of the session.
class EntitlementContext {
  const EntitlementContext({
    required this.license,
    required this.features,
    required this.enforcementMode,
    required this.resolvedAt,
  });

  final LicenseSummary license;
  final Map<String, ResolvedFeature> features;

  /// `off` | `shadow` | `enforcing`. The platform's rollout state.
  final String enforcementMode;

  final DateTime resolvedAt;

  /// The permissive context used before the document has loaded, and the one the
  /// shell falls back to when the RPC fails.
  ///
  /// Failing OPEN is deliberate and is the opposite of the usual security
  /// default, for one reason: this object is a UX hint, the server is the
  /// boundary, and a network blip that silently hid half an operator's console
  /// would be indistinguishable from a downgrade they never agreed to.
  static final unknown = EntitlementContext(
    license: const LicenseSummary(planKey: '', planNameAr: '', status: 'none'),
    features: const {},
    enforcementMode: 'off',
    resolvedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  bool get isLoaded => features.isNotEmpty;

  /// Is the platform actually enforcing today? While `off` or `shadow`, the
  /// server allows everything, so the console must not pretend otherwise —
  /// hiding a module the backend would happily serve is its own kind of bug.
  bool get isEnforcing => enforcementMode == 'enforcing';

  ResolvedFeature? feature(String key) => features[key];

  /// The gate every call site uses. `null` means "this surface is not licensed
  /// at all", which is always allowed.
  bool allows(String? featureKey) {
    if (featureKey == null) return true;
    if (!isEnforcing) return true;
    final f = features[featureKey];
    if (f == null) return true; 
    return f.isOn;
  }

  /// Purchasable-but-off, i.e. show it locked with an upgrade affordance rather
  /// than hiding it. An unpurchasable or ungated feature is hidden instead.
  bool isLocked(String? featureKey) {
    if (featureKey == null || allows(featureKey)) return false;
    final f = features[featureKey];
    return f != null && f.isPublic && f.enforced;
  }

  /// Every limit feature, for the usage bars on the billing screen.
  List<ResolvedFeature> get limits =>
      features.values.where((f) => f.valueType == 'limit').toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<ResolvedFeature> byCategory(String categoryKey) =>
      features.values.where((f) => f.categoryKey == categoryKey).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  factory EntitlementContext.fromRpc(Map<String, dynamic> json) {
    final rawFeatures = (json['features'] as Map?) ?? const {};
    return EntitlementContext(
      license: LicenseSummary.fromJson(
        Map<String, dynamic>.from((json['license'] as Map?) ?? const {}),
      ),
      features: {
        for (final entry in rawFeatures.entries)
          entry.key as String: ResolvedFeature.fromJson(
            entry.key as String,
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
      enforcementMode: (json['enforcement_mode'] as String?) ?? 'off',
      resolvedAt:
          DateTime.tryParse((json['resolved_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

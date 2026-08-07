import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/platform_licensing_usecases.dart';
import 'platform_licensing_state.dart';

/// Drives every screen in the licensing console.
///
/// One cubit rather than seven because the sections read each other constantly
/// — the licence detail needs the plan list, the plan builder needs the
/// catalog, the health screen links into both — and seven cubits would mean
/// seven copies of the same catalog fetched on every navigation.
///
/// Every mutating method reloads only what its action can have changed, and
/// reports failure through `actionError` rather than by replacing the screen:
/// an operator who mistyped a reason must still be looking at the form they
/// mistyped it in.
class PlatformLicensingCubit extends Cubit<PlatformLicensingState> {
  PlatformLicensingCubit({
    required GetFeatureCatalogUseCase getCatalog,
    required SetFeatureStatusUseCase setFeatureStatus,
    required GetPlansUseCase getPlans,
    required GetPlanDetailUseCase getPlanDetail,
    required SavePlanUseCase savePlan,
    required ClonePlanUseCase clonePlan,
    required PreviewPlanUseCase previewPlan,
    required GetOfficeLicensesUseCase getLicenses,
    required GetOfficeLicenseUseCase getLicense,
    required AssignPlanUseCase assignPlan,
    required SetLicenseStatusUseCase setLicenseStatus,
    required ExtendTrialUseCase extendTrial,
    required SetFeatureOverrideUseCase setOverride,
    required ClearFeatureOverrideUseCase clearOverride,
    required GetBillingOverviewUseCase getBilling,
    required IssueInvoiceUseCase issueInvoice,
    required RecordInvoicePaymentUseCase recordPayment,
    required VoidInvoiceUseCase voidInvoice,
    required GetPlatformUsageUseCase getUsage,
    required GetLicenseAuditUseCase getAudit,
    required GetLicensingHealthUseCase getHealth,
    required GetLicensingSettingsUseCase getSettings,
    required UpdateLicensingSettingsUseCase updateSettings,
    required RunLicensingLifecycleUseCase runLifecycle,
    required RunBillingCycleUseCase runBillingCycle,
  }) : _getCatalog = getCatalog,
       _setFeatureStatus = setFeatureStatus,
       _getPlans = getPlans,
       _getPlanDetail = getPlanDetail,
       _savePlan = savePlan,
       _clonePlan = clonePlan,
       _previewPlan = previewPlan,
       _getLicenses = getLicenses,
       _getLicense = getLicense,
       _assignPlan = assignPlan,
       _setLicenseStatus = setLicenseStatus,
       _extendTrial = extendTrial,
       _setOverride = setOverride,
       _clearOverride = clearOverride,
       _getBilling = getBilling,
       _issueInvoice = issueInvoice,
       _recordPayment = recordPayment,
       _voidInvoice = voidInvoice,
       _getUsage = getUsage,
       _getAudit = getAudit,
       _getHealth = getHealth,
       _getSettings = getSettings,
       _updateSettings = updateSettings,
       _runLifecycle = runLifecycle,
       _runBillingCycle = runBillingCycle,
       super(const PlatformLicensingInitial());

  final GetFeatureCatalogUseCase _getCatalog;
  final SetFeatureStatusUseCase _setFeatureStatus;
  final GetPlansUseCase _getPlans;
  final GetPlanDetailUseCase _getPlanDetail;
  final SavePlanUseCase _savePlan;
  final ClonePlanUseCase _clonePlan;
  final PreviewPlanUseCase _previewPlan;
  final GetOfficeLicensesUseCase _getLicenses;
  final GetOfficeLicenseUseCase _getLicense;
  final AssignPlanUseCase _assignPlan;
  final SetLicenseStatusUseCase _setLicenseStatus;
  final ExtendTrialUseCase _extendTrial;
  final SetFeatureOverrideUseCase _setOverride;
  final ClearFeatureOverrideUseCase _clearOverride;
  final GetBillingOverviewUseCase _getBilling;
  final IssueInvoiceUseCase _issueInvoice;
  final RecordInvoicePaymentUseCase _recordPayment;
  final VoidInvoiceUseCase _voidInvoice;
  final GetPlatformUsageUseCase _getUsage;
  final GetLicenseAuditUseCase _getAudit;
  final GetLicensingHealthUseCase _getHealth;
  final GetLicensingSettingsUseCase _getSettings;
  final UpdateLicensingSettingsUseCase _updateSettings;
  final RunLicensingLifecycleUseCase _runLifecycle;
  final RunBillingCycleUseCase _runBillingCycle;

  PlatformLicensingLoaded? get _loaded => state is PlatformLicensingLoaded
      ? state as PlatformLicensingLoaded
      : null;

  /// Loads the whole console in one pass.
  ///
  /// Nine round trips against a platform with three offices — deliberately not
  /// optimised. The alternative is a lazy per-tab load that makes the health
  /// counts wrong until the operator visits every screen.
  Future<void> load() async {
    emit(const PlatformLicensingLoading());
    try {
      final catalog = _getCatalog();
      final plans = _getPlans();
      final licenses = _getLicenses();
      final settings = _getSettings();
      final health = _getHealth();

      emit(
        PlatformLicensingLoaded(
          catalog: await catalog,
          plans: await plans,
          licenses: await licenses,
          settings: await settings,
          health: await health,
        ),
      );

      // The heavier aggregates follow, so the console is usable while they run.
      await Future.wait([loadUsage(), loadBilling(), loadAudit()]);
    } catch (error) {
      emit(PlatformLicensingError(_message(error)));
    }
  }

  Future<void> loadUsage() =>
      _section(() async => _loaded?.copyWith(usage: await _getUsage()));

  Future<void> loadBilling({String? officeId, String? status}) => _section(
    () async => _loaded?.copyWith(
      billing: await _getBilling(officeId: officeId, status: status),
    ),
  );

  Future<void> loadAudit({Map<String, dynamic>? filters}) => _section(() async {
    final f = filters ?? _loaded?.auditFilters ?? const {};
    return _loaded?.copyWith(
      audit: await _getAudit(filters: f),
      auditFilters: f,
    );
  });

  Future<void> loadHealth() =>
      _section(() async => _loaded?.copyWith(health: await _getHealth()));

  // ── Catalog ────────────────────────────────────────────────────────────────

  void searchFeatures(String query) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(featureSearch: query));
  }

  /// Null clears the axis. Every catalog filter is a pure narrowing of data the
  /// console already holds, so none of them refetch.
  void filterFeaturesByCategory(String? categoryKey) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        featureCategoryFilter: categoryKey,
        clearFeatureCategoryFilter: categoryKey == null,
      ),
    );
  }

  /// `enforced` | `declared` | null.
  void filterFeaturesByEnforcement(String? enforcement) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        featureEnforcementFilter: enforcement,
        clearFeatureEnforcementFilter: enforcement == null,
      ),
    );
  }

  void filterFeaturesByStatus(String? status) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        featureStatusFilter: status,
        clearFeatureStatusFilter: status == null,
      ),
    );
  }

  void clearFeatureFilters() {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        featureSearch: '',
        clearFeatureCategoryFilter: true,
        clearFeatureEnforcementFilter: true,
        clearFeatureStatusFilter: true,
      ),
    );
  }

  void selectFeature(String key) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedFeatureKey: key));
  }

  void clearFeatureSelection() {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(clearSelectedFeature: true));
  }

  /// The platform-wide kill switch, among others. Reloads the catalog *and* the
  /// health screen, because disabling a feature can instantly create a
  /// "sold but not delivered" row on an active plan.
  Future<void> setFeatureStatus(String key, String status) => _action(() async {
    await _setFeatureStatus(key, status);
    return _loaded?.copyWith(
      catalog: await _getCatalog(),
      health: await _getHealth(),
      actionMessage: 'تم تحديث حالة الميزة.',
    );
  });

  // ── Plans ──────────────────────────────────────────────────────────────────

  Future<void> selectPlan(String planId) => _action(() async {
    final detail = await _getPlanDetail(planId);
    return _loaded?.copyWith(selectedPlan: detail, clearPlanPreview: true);
  });

  void clearPlanSelection() {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(clearSelectedPlan: true, clearPlanPreview: true));
  }

  /// [values] must be the COMPLETE feature map for the plan: the server replaces
  /// it wholesale, and an omitted key means "fall through to the catalog
  /// default", not "leave it alone".
  Future<void> savePlanValues(
    String planId,
    Map<String, Object?> values,
    String reason,
  ) => _action(() async {
    final detail = await _savePlan({
      'id': planId,
      'features': values,
      'reason': reason,
    });
    return _loaded?.copyWith(
      selectedPlan: detail,
      plans: await _getPlans(),
      health: await _getHealth(),
      // The sentence that matters: this took effect for every subscribed office
      // the moment it saved, because the resolver reads plan values live.
      actionMessage:
          'تم الحفظ. سرى التغيير فورًا على كل مكتب مشترك في هذه الباقة، '
          'وحُفظت النسخة السابقة في السجل.',
    );
  });

  Future<void> savePlanDetails(Map<String, dynamic> payload) =>
      _action(() async {
        final detail = await _savePlan(payload);
        return _loaded?.copyWith(
          selectedPlan: detail,
          plans: await _getPlans(),
          actionMessage: 'تم حفظ بيانات الباقة.',
        );
      });

  Future<void> clonePlan(String planId, String key, String name) =>
      _action(() async {
        final detail = await _clonePlan(planId, key, name);
        return _loaded?.copyWith(
          selectedPlan: detail,
          plans: await _getPlans(),
          actionMessage: 'تم إنشاء نسخة كمسودة.',
        );
      });

  Future<void> previewPlan(String planId) => _action(() async {
    return _loaded?.copyWith(planPreview: await _previewPlan(planId));
  });

  /// Dismisses the resolver preview without touching the selection — the panel
  /// it renders in is a read-out the operator asked for, so they must be able to
  /// put it away again.
  void clearPlanPreview() {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(clearPlanPreview: true));
  }

  // ── Licences ───────────────────────────────────────────────────────────────

  void filterLicenses(String? status) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(
      status == null
          ? loaded.copyWith(clearLicenseStatusFilter: true)
          : loaded.copyWith(licenseStatusFilter: status),
    );
  }

  Future<void> selectOffice(String officeId) => _action(() async {
    return _loaded?.copyWith(selectedOffice: await _getLicense(officeId));
  });

  void clearOfficeSelection() {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(clearSelectedOffice: true));
  }

  Future<void> assignPlan(
    String officeId,
    String planId, {
    String cycle = 'monthly',
    Map<String, dynamic> options = const {},
  }) => _action(() async {
    final detail = await _assignPlan(
      officeId,
      planId,
      cycle: cycle,
      options: options,
    );
    return _loaded?.copyWith(
      selectedOffice: detail,
      licenses: await _getLicenses(),
      plans: await _getPlans(),
      actionMessage: 'تم تعيين الباقة.',
    );
  });

  Future<void> setLicenseStatus(
    String officeId,
    String status,
    String reason,
  ) => _action(() async {
    final detail = await _setLicenseStatus(officeId, status, reason);
    return _loaded?.copyWith(
      selectedOffice: detail,
      licenses: await _getLicenses(),
      health: await _getHealth(),
      actionMessage: status == 'suspended'
          // Said explicitly at the moment of the action, because this is the
          // decision most often misunderstood as a blackout.
          ? 'تم الإيقاف. المكتب الآن في وضع القراءة فقط: التذاكر المُباعة '
                'والرحلات الجارية ودخول الكباتن تكمل كالمعتاد.'
          : 'تم تحديث حالة الترخيص.',
    );
  });

  Future<void> extendTrial(String officeId, int days, String reason) =>
      _action(() async {
        final detail = await _extendTrial(officeId, days, reason);
        return _loaded?.copyWith(
          selectedOffice: detail,
          licenses: await _getLicenses(),
          health: await _getHealth(),
          actionMessage: 'تم تمديد الفترة التجريبية.',
        );
      });

  // ── Overrides ──────────────────────────────────────────────────────────────

  Future<void> setOverride(
    String officeId,
    String featureKey,
    Object? value,
    String reason, {
    DateTime? expiresAt,
  }) => _action(() async {
    final detail = await _setOverride(
      officeId,
      featureKey,
      value,
      reason,
      expiresAt: expiresAt,
    );
    return _loaded?.copyWith(
      selectedOffice: detail,
      licenses: await _getLicenses(),
      actionMessage: 'تم حفظ الاستثناء.',
    );
  });

  Future<void> clearOverride(
    String officeId,
    String featureKey,
    String reason,
  ) => _action(() async {
    final detail = await _clearOverride(officeId, featureKey, reason);
    return _loaded?.copyWith(
      selectedOffice: detail,
      licenses: await _getLicenses(),
      actionMessage: 'تمت إزالة الاستثناء.',
    );
  });

  // ── Billing ────────────────────────────────────────────────────────────────

  Future<void> issueInvoice(String officeId) => _action(() async {
    await _issueInvoice(officeId);
    return _loaded?.copyWith(
      billing: await _getBilling(),
      selectedOffice: _loaded?.selectedOffice == null
          ? null
          : await _getLicense(officeId),
      actionMessage: 'تم إصدار الفاتورة.',
    );
  });

  Future<void> recordPayment(
    String invoiceId,
    String method,
    String? reference,
  ) => _action(() async {
    await _recordPayment(invoiceId, method, reference);
    return _loaded?.copyWith(
      billing: await _getBilling(),
      licenses: await _getLicenses(),
      health: await _getHealth(),
      actionMessage: 'تم تسجيل السداد.',
    );
  });

  Future<void> voidInvoice(String invoiceId, String reason) =>
      _action(() async {
        await _voidInvoice(invoiceId, reason);
        return _loaded?.copyWith(
          billing: await _getBilling(),
          actionMessage: 'تم إبطال الفاتورة.',
        );
      });

  // ── Settings and the scheduled jobs ────────────────────────────────────────

  /// The kill switch. `off` restores pre-licensing behaviour instantly.
  Future<void> setEnforcementMode(String mode) => _action(() async {
    final settings = await _updateSettings({
      'enforcement_mode': mode,
      'reason': 'تغيير وضع التطبيق من وحدة التحكم',
    });
    return _loaded?.copyWith(
      settings: settings,
      health: await _getHealth(),
      actionMessage: switch (mode) {
        'off' => 'تم تعطيل التطبيق. لا تُطبَّق أي حدود الآن.',
        'shadow' =>
          'وضع الظل مفعّل: تُسجَّل التجاوزات ولا يُمنع شيء. '
              'أي تسجيل هنا يعني أن حدًّا مضبوطًا خطأ، لا أن مكتبًا يتحايل.',
        _ => 'التطبيق مفعّل. تُطبَّق الحدود الآن على الإنشاء الجديد فقط.',
      },
    );
  });

  Future<void> updateSettings(Map<String, dynamic> payload) =>
      _action(() async {
        return _loaded?.copyWith(
          settings: await _updateSettings(payload),
          actionMessage: 'تم حفظ الإعدادات.',
        );
      });

  /// "Run now" for the nightly jobs. Far more useful than waiting for a
  /// schedule while investigating one customer's state.
  Future<void> runLifecycle() => _action(() async {
    final result = await _runLifecycle();
    return _loaded?.copyWith(
      licenses: await _getLicenses(),
      health: await _getHealth(),
      actionMessage:
          'تم تشغيل دورة الحياة: '
          '${result['suspended'] ?? 0} إيقاف، '
          '${result['downgraded'] ?? 0} تخفيض، '
          '${result['warned'] ?? 0} تنبيه.',
    );
  });

  Future<void> runBillingCycle() => _action(() async {
    final result = await _runBillingCycle();
    return _loaded?.copyWith(
      billing: await _getBilling(),
      licenses: await _getLicenses(),
      actionMessage: 'تم إصدار ${result['invoices_issued'] ?? 0} فاتورة تجديد.',
    );
  });

  void clearActionFeedback() {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith());
  }

  /// A background section refresh: it must never surface an error banner or a
  /// spinner over the whole console.
  Future<void> _section(Future<PlatformLicensingLoaded?> Function() run) async {
    if (_loaded == null) return;
    try {
      final next = await run();
      if (next != null) emit(next);
    } catch (_) {
      // Leave the section as it was. A failed aggregate is not a reason to take
      // the plan list down with it.
    }
  }

  Future<void> _action(Future<PlatformLicensingLoaded?> Function() run) async {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(isBusy: true));
    try {
      final next = (await run()) ?? _loaded ?? loaded;
      // The feedback fields are re-passed explicitly: copyWith deliberately
      // does NOT carry them forward, so clearing the busy flag would otherwise
      // throw away the message the action just produced.
      emit(
        next.copyWith(
          isBusy: false,
          actionMessage: next.actionMessage,
          actionError: next.actionError,
        ),
      );
    } catch (error) {
      emit(
        (_loaded ?? loaded).copyWith(
          isBusy: false,
          actionError: _message(error),
        ),
      );
    }
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}

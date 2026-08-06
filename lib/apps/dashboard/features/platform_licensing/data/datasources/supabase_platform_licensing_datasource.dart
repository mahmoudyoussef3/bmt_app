import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';
import 'platform_licensing_datasource.dart';

/// The console's single door to the licensing RPCs.
///
/// No table reads: every licensing table has SELECT policies but **no
/// INSERT/UPDATE/DELETE policy at all, for anyone**, so the only write path is
/// a `security definer` RPC that audits itself. Reading through the same RPCs
/// keeps the console and the audit trail describing the same events.
class SupabasePlatformLicensingDatasource
    implements PlatformLicensingDatasource {
  SupabasePlatformLicensingDatasource(this._client);

  final SupabaseClient _client;

  Future<Object?> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc(fn, params: params);
    } catch (error) {
      throw _handleError(error);
    }
  }

  Map<String, dynamic> _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? raw) => [
    for (final e in (raw as List?) ?? const [])
      Map<String, dynamic>.from(e as Map),
  ];

  // ── Catalog ─────────────────────────────────────────────────────────────────

  @override
  Future<FeatureCatalog> catalog() async =>
      FeatureCatalog.fromJson(_map(await _rpc('platform_feature_catalog')));

  @override
  Future<void> upsertFeature(Map<String, dynamic> payload) async {
    await _rpc('platform_upsert_feature', {'p_payload': payload});
  }

  @override
  Future<void> setFeatureStatus(String key, String status) async {
    await _rpc('platform_set_feature_status', {
      'p_key': key,
      'p_status': status,
    });
  }

  // ── Plans ───────────────────────────────────────────────────────────────────

  @override
  Future<List<LicensingPlan>> plans() async => [
    for (final p in _list(await _rpc('platform_list_plans')))
      LicensingPlan.fromJson(p),
  ];

  @override
  Future<PlanDetail> planDetail(String planId) async => PlanDetail.fromJson(
    _map(await _rpc('platform_plan_detail', {'p_plan_id': planId})),
  );

  @override
  Future<PlanDetail> savePlan(Map<String, dynamic> payload) async =>
      PlanDetail.fromJson(
        _map(await _rpc('platform_save_plan', {'p_payload': payload})),
      );

  @override
  Future<PlanDetail> clonePlan(
    String planId,
    String newKey,
    String newName,
  ) async => PlanDetail.fromJson(
    _map(
      await _rpc('platform_clone_plan', {
        'p_plan_id': planId,
        'p_new_key': newKey,
        'p_new_name': newName,
      }),
    ),
  );

  @override
  Future<Map<String, dynamic>> comparePlans(List<String> planIds) async =>
      _map(await _rpc('platform_compare_plans', {'p_plan_ids': planIds}));

  @override
  Future<Map<String, dynamic>> previewPlan(String planId) async =>
      _map(await _rpc('platform_preview_plan', {'p_plan_id': planId}));

  // ── Licenses ────────────────────────────────────────────────────────────────

  @override
  Future<List<OfficeLicenseRow>> licenses() async => [
    for (final r in _list(await _rpc('platform_list_licenses')))
      OfficeLicenseRow.fromJson(r),
  ];

  @override
  Future<OfficeLicenseDetail> officeLicense(String officeId) async =>
      OfficeLicenseDetail.fromJson(
        _map(await _rpc('platform_office_license', {'p_office_id': officeId})),
      );

  @override
  Future<OfficeLicenseDetail> assignPlan(
    String officeId,
    String planId, {
    String cycle = 'monthly',
    Map<String, dynamic> options = const {},
  }) async => OfficeLicenseDetail.fromJson(
    _map(
      await _rpc('platform_assign_plan', {
        'p_office_id': officeId,
        'p_plan_id': planId,
        'p_cycle': cycle,
        'p_options': options,
      }),
    ),
  );

  @override
  Future<OfficeLicenseDetail> setLicenseStatus(
    String officeId,
    String status,
    String reason,
  ) async => OfficeLicenseDetail.fromJson(
    _map(
      await _rpc('platform_set_license_status', {
        'p_office_id': officeId,
        'p_status': status,
        'p_reason': reason,
      }),
    ),
  );

  @override
  Future<OfficeLicenseDetail> startTrial(
    String officeId,
    String planId,
    int days,
  ) async => OfficeLicenseDetail.fromJson(
    _map(
      await _rpc('platform_start_trial', {
        'p_office_id': officeId,
        'p_plan_id': planId,
        'p_days': days,
      }),
    ),
  );

  @override
  Future<OfficeLicenseDetail> extendTrial(
    String officeId,
    int days,
    String reason,
  ) async => OfficeLicenseDetail.fromJson(
    _map(
      await _rpc('platform_extend_trial', {
        'p_office_id': officeId,
        'p_days': days,
        'p_reason': reason,
      }),
    ),
  );

  // ── Overrides ───────────────────────────────────────────────────────────────

  @override
  Future<OfficeLicenseDetail> setOverride(
    String officeId,
    String featureKey,
    Object? value,
    String reason, {
    DateTime? expiresAt,
  }) async => OfficeLicenseDetail.fromJson(
    _map(
      await _rpc('platform_set_override', {
        'p_office_id': officeId,
        'p_key': featureKey,
        'p_value': value,
        'p_reason': reason,
        'p_expires_at': expiresAt?.toIso8601String(),
      }),
    ),
  );

  @override
  Future<OfficeLicenseDetail> clearOverride(
    String officeId,
    String featureKey,
    String reason,
  ) async => OfficeLicenseDetail.fromJson(
    _map(
      await _rpc('platform_clear_override', {
        'p_office_id': officeId,
        'p_key': featureKey,
        'p_reason': reason,
      }),
    ),
  );

  // ── Billing ─────────────────────────────────────────────────────────────────

  @override
  Future<BillingOverview> billing({String? officeId, String? status}) async =>
      BillingOverview.fromJson(
        _map(
          await _rpc('platform_billing_overview', {
            'p_filters': {'office_id': ?officeId, 'status': ?status},
          }),
        ),
      );

  @override
  Future<void> issueInvoice(
    String officeId, {
    Map<String, dynamic> options = const {},
  }) async {
    await _rpc('platform_issue_invoice', {
      'p_office_id': officeId,
      'p_options': options,
    });
  }

  @override
  Future<void> recordPayment(
    String invoiceId,
    String method,
    String? reference,
  ) async {
    await _rpc('platform_record_payment', {
      'p_invoice_id': invoiceId,
      'p_method': method,
      'p_reference': reference,
    });
  }

  @override
  Future<void> voidInvoice(String invoiceId, String reason) async {
    await _rpc('platform_void_invoice', {
      'p_invoice_id': invoiceId,
      'p_reason': reason,
    });
  }

  // ── Ops ─────────────────────────────────────────────────────────────────────

  @override
  Future<List<OfficeUsageRow>> usage() async => [
    for (final r in _list(await _rpc('platform_usage_report')))
      OfficeUsageRow.fromJson(r),
  ];

  @override
  Future<List<LicenseAuditEntry>> audit({
    Map<String, dynamic> filters = const {},
    int limit = 100,
    int offset = 0,
  }) async => [
    for (final e in _list(
      await _rpc('platform_audit_log', {
        'p_filters': filters,
        'p_limit': limit,
        'p_offset': offset,
      }),
    ))
      LicenseAuditEntry.fromJson(e),
  ];

  @override
  Future<LicensingHealth> health() async =>
      LicensingHealth.fromJson(_map(await _rpc('platform_licensing_health')));

  @override
  Future<LicensingSettings> settings() async =>
      LicensingSettings.fromJson(_map(await _rpc('platform_settings_read')));

  @override
  Future<LicensingSettings> updateSettings(
    Map<String, dynamic> payload,
  ) async => LicensingSettings.fromJson(
    _map(await _rpc('platform_update_settings', {'p_payload': payload})),
  );

  @override
  Future<Map<String, dynamic>> runLifecycle() async =>
      _map(await _rpc('platform_run_licensing_lifecycle'));

  @override
  Future<Map<String, dynamic>> runBillingCycle() async =>
      _map(await _rpc('platform_run_billing_cycle'));

  /// Turns the server's machine codes into the sentence the operator needs.
  ///
  /// Same construction the wallet datasource uses, and for the same reason:
  /// each code names a specific control that fired, and an operator told
  /// "the reason is required" fixes it, while one told "error 23514" calls
  /// support.
  Exception _handleError(Object error) {
    if (error is PostgrestException) {
      final message = error.message;
      final translated = _messages.entries
          .where((entry) => message.contains(entry.key))
          .map((entry) => entry.value)
          .firstOrNull;
      if (translated != null) return Exception(translated);
      return Exception('خطأ بقاعدة البيانات: $message');
    }
    return Exception(error.toString().replaceAll('Exception: ', ''));
  }

  static const Map<String, String> _messages = {
    'platform_admin_required': 'هذه الشاشة متاحة لمديري المنصة فقط.',
    'reason_required': 'السبب مطلوب (٨ أحرف على الأقل).',
    'unknown_feature': 'هذه الميزة غير موجودة في الكتالوج.',
    'feature_key_required': 'مفتاح الميزة مطلوب.',
    'feature_value_null': 'لا يمكن ترك القيمة فارغة — احذف الصف بدلاً من ذلك.',
    'feature_value_type_mismatch': 'نوع القيمة لا يطابق نوع الميزة.',
    'feature_value_invalid_limit':
        'الحد يجب أن يكون رقمًا صحيحًا غير سالب أو «بلا حدود».',
    'feature_value_below_min': 'القيمة أقل من الحد الأدنى المسموح للميزة.',
    'feature_value_above_max': 'القيمة أعلى من الحد الأقصى المسموح للميزة.',
    'feature_value_not_allowed': 'هذه القيمة غير مسموحة لهذه الميزة.',
    'feature_schema_incomplete': 'الميزة من نوع «مستوى» بلا قائمة قيم مسموحة.',
    'feature_dependency_cycle': 'هذه التبعية تُنشئ حلقة مغلقة.',
    'plan_not_found': 'لم يتم العثور على الباقة.',
    'plan_archived': 'لا يمكن تعيين باقة مؤرشفة.',
    'license_not_found': 'هذا المكتب بلا ترخيص بعد.',
    'not_trialing': 'هذا المكتب ليس في فترة تجريبية.',
    'trial_days_required': 'عدد أيام التجربة مطلوب.',
    'invoice_not_payable':
        'لا يمكن تسجيل سداد لهذه الفاتورة في حالتها الحالية.',
    'invoice_not_voidable':
        'لا يمكن إبطال فاتورة مسددة — عكس مبلغ محصَّل استرداد وليس تعديلًا.',
    'audit_is_append_only': 'سجل التغييرات غير قابل للتعديل أو الحذف.',
    'duplicate key value': 'هذا المفتاح مستخدم بالفعل.',
  };
}

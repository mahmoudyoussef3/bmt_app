import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A refusal that came from the entitlement axis rather than the role axis.
///
/// The whole point of keeping `role ∧ entitlement ∧ quota` as three separate
/// predicates is that when an action is refused the system knows **which one
/// said no** — and "you don't have permission" when the truth is "your plan
/// doesn't include this" is the difference between a support ticket and a sale.
///
/// The server carries the full verdict across in the exception's `detail`
/// (`raise exception … using detail = <verdict jsonb>`), so this class can name
/// the limit, the numbers and the plan instead of showing `quota_exceeded`.
class LicensingFailure implements Exception {
  const LicensingFailure({
    required this.code,
    required this.message,
    this.featureKey,
    this.featureNameAr,
    this.limit,
    this.used,
    this.planKey,
    this.blockedBy,
  });

  /// One of the six refusal codes in §7.2.
  final String code;

  /// Arabic, user-facing. Every caller shows this and nothing else.
  final String message;

  final String? featureKey;
  final String? featureNameAr;
  final int? limit;
  final int? used;
  final String? planKey;
  final String? blockedBy;

  bool get isQuota => code == quotaExceeded;

  static const notAuthorized = 'not_authorized';
  static const featureNotLicensed = 'feature_not_licensed';
  static const dependencyBlocked = 'feature_dependency_blocked';
  static const quotaExceeded = 'quota_exceeded';
  static const licenseSuspended = 'license_suspended';
  static const licenseExpired = 'license_expired';

  static const _codes = {
    notAuthorized,
    featureNotLicensed,
    dependencyBlocked,
    quotaExceeded,
    licenseSuspended,
    licenseExpired,
  };

  /// Six codes, mapped the same way every other datasource maps the server's
  /// machine codes. No new error infrastructure.
  static const Map<String, String> messages = {
    notAuthorized: 'ليس لديك صلاحية تنفيذ هذه العملية. تواصل مع مالك المكتب.',
    featureNotLicensed: 'هذه الميزة غير متاحة في باقتك الحالية.',
    dependencyBlocked: 'هذه الميزة تتطلب تفعيل ميزة أخرى أولًا.',
    quotaExceeded: 'وصلت إلى حد الباقة لهذا العنصر.',
    licenseSuspended:
        'حساب المكتب في وضع القراءة فقط بسبب حالة الاشتراك. ما هو قائم يكمل كالمعتاد.',
    licenseExpired: 'انتهى ترخيص المكتب. جدّد الاشتراك لاستئناف الإنشاء.',
  };

  /// Returns null when [error] is not a licensing refusal, so a caller can fall
  /// through to its own error mapping unchanged.
  static LicensingFailure? tryParse(Object error) {
    if (error is LicensingFailure) return error;
    if (error is! PostgrestException) return null;

    final code = _codes.firstWhere(
      (c) => error.message.contains(c),
      orElse: () => '',
    );
    if (code.isEmpty) return null;

    final verdict = _verdict(error.details);

    final feature =
        verdict?['feature'] as String? ?? verdict?['key'] as String?;
    final limit = (verdict?['limit'] as num?)?.toInt();
    final used = (verdict?['used'] as num?)?.toInt();

    return LicensingFailure(
      code: code,
      message: messages[code] ?? 'تعذّر تنفيذ العملية.',
      featureKey: feature,
      limit: limit,
      used: used,
      planKey: verdict?['plan_key'] as String?,
      blockedBy: verdict?['blocked_by'] as String?,
    );
  }

  /// `details` arrives as the raw `DETAIL:` payload, which is the verdict jsonb
  /// serialised by Postgres. It is best-effort by design: a refusal must still
  /// be reported when the detail is missing or unparseable.
  static Map<String, dynamic>? _verdict(Object? details) {
    if (details is Map) return Map<String, dynamic>.from(details);
    if (details is! String) return null;
    final start = details.indexOf('{');
    final end = details.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(details.substring(start, end + 1));
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => message;
}

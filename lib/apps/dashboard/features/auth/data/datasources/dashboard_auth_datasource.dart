import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/office_context.dart';
import '../../domain/entities/dashboard_auth_failure.dart';
import '../../domain/repositories/dashboard_auth_repository.dart';

/// Dashboard authentication: **name + password, nothing else.**
///
/// Supabase Auth signs in with an email internally, so [signIn] first maps the typed
/// name to that account's login address via `resolve_office_user_login` — the same
/// indirection `resolve_captain_login` already uses for phone numbers, so the codebase
/// keeps one pattern rather than two. The address never surfaces in the UI.
///
/// [signUp] is the other half: an operator with no account at all registers their own
/// office. It creates the auth user with the client SDK's own `signUp` — no service-role
/// key is involved, unlike the platform-admin onboarding flow — and then calls
/// `register_office`, which decides everything worth tampering with server-side. The
/// office it creates is `active` (its dashboard works at once) and `draft` (invisible to
/// passengers until the platform publishes it).
class DashboardAuthDatasource implements DashboardAuthRepository {
  const DashboardAuthDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// Signs in and returns the operator's office context in one flow.
  ///
  /// Throws [DashboardAuthFailure] with a user-facing Arabic message on every
  /// failure path.
  @override
  Future<OfficeContext> signIn({
    required String username,
    required String password,
  }) async {
    final resolved = await _resolveLoginEmail(username);

    try {
      await _supabase.auth.signInWithPassword(
        email: resolved,
        password: password,
      );
    } on AuthException {
      throw const DashboardAuthFailure(
        'اسم المستخدم أو كلمة المرور غير صحيحة.',
      );
    } catch (_) {
      throw const DashboardAuthFailure('تعذر تسجيل الدخول. حاول مرة أخرى.');
    }

    try {
      return await loadContext();
    } on DashboardAuthFailure catch (failure) {
      if (failure.code == _noOfficeCode) {
        try {
          await _supabase.rpc('register_office');
          return await loadContext();
        } catch (_) {}
      }
      await signOut();
      rethrow;
    } catch (e) {
      await signOut();
      rethrow;
    }
  }

  /// Registers a brand-new office and signs its owner in.
  ///
  /// The office name is written into user metadata as well as passed to the RPC: if the
  /// project ever turns email confirmation on, `signUp` returns no session, the office
  /// cannot be created yet, and the name would otherwise be lost by the time the owner
  /// comes back to sign in.
  @override
  Future<OfficeContext> signUp({
    required String email,
    required String password,
    required String officeName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedOffice = officeName.trim();

    final AuthResponse response;
    try {
      response = await _supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {'role': 'office_user', 'pending_office_name': trimmedOffice},
      );
    } on AuthException catch (e) {
      throw DashboardAuthFailure(_signUpMessage(e));
    } catch (_) {
      throw const DashboardAuthFailure('تعذر إنشاء الحساب. حاول مرة أخرى.');
    }

    if (response.session == null) {
      throw const DashboardAuthFailure(
        'تم إنشاء الحساب. فعّل الرابط المرسل إلى بريدك الإلكتروني ثم سجّل الدخول '
        'لإكمال إنشاء المكتب.',
      );
    }

    try {
      await _supabase.rpc(
        'register_office',
        params: {'p_office_name': trimmedOffice},
      );
    } on PostgrestException catch (e) {
      throw DashboardAuthFailure(_registerMessage(e.message));
    } catch (_) {
      throw const DashboardAuthFailure('تعذر إنشاء المكتب. حاول مرة أخرى.');
    }

    return loadContext();
  }

  String _signUpMessage(AuthException e) {
    final raw = e.message.toLowerCase();
    if (raw.contains('already registered') ||
        raw.contains('already been registered') ||
        raw.contains('user_already_exists')) {
      return 'هذا البريد الإلكتروني مسجّل بالفعل. سجّل الدخول بدلاً من ذلك.';
    }
    if (raw.contains('password')) {
      return 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.';
    }
    if (raw.contains('email')) {
      return 'البريد الإلكتروني غير صالح.';
    }
    return 'تعذر إنشاء الحساب. حاول مرة أخرى.';
  }

  /// `register_office` raises bare machine codes, so the Arabic lives here — the same
  /// split the platform onboarding datasource uses.
  String _registerMessage(String raw) {
    if (raw.contains('already_registered')) {
      return 'هذا الحساب مرتبط بمكتب بالفعل.';
    }
    if (raw.contains('driver_cannot_register_office')) {
      return 'حساب الكابتن لا يمكنه إنشاء مكتب.';
    }
    if (raw.contains('invalid_office_name')) {
      return 'اسم المكتب قصير جداً (3 أحرف على الأقل).';
    }
    if (raw.contains('office_name_too_long')) {
      return 'اسم المكتب طويل جداً.';
    }
    if (raw.contains('not_authenticated')) {
      return 'انتهت الجلسة. حاول مرة أخرى.';
    }
    return 'تعذر إنشاء المكتب. حاول مرة أخرى.';
  }

  Future<String> _resolveLoginEmail(String username) async {
    final Object? result;
    try {
      result = await _supabase.rpc(
        'resolve_office_user_login',
        params: {'p_username': username},
      );
    } catch (_) {
      throw const DashboardAuthFailure('تعذر الاتصال بالخادم. تحقق من الشبكة.');
    }

    final map = result is Map ? Map<String, dynamic>.from(result) : null;
    if (map == null || map['outcome'] != 'ready') {
      throw const DashboardAuthFailure(
        'اسم المستخدم أو كلمة المرور غير صحيحة.',
      );
    }
    return map['login_email'] as String;
  }

  /// Loads the office context for the current session. Called after sign-in and on
  /// app start when a cached Supabase session already exists.
  @override
  Future<OfficeContext> loadContext() async {
    final Object? result;
    try {
      result = await _supabase.rpc('current_office_context');
    } on PostgrestException catch (e) {
      if (e.message.contains('not_an_office_user')) {
        throw const DashboardAuthFailure(
          'هذا الحساب غير مرتبط بأي مكتب. تواصل مع المسؤول.',
          code: _noOfficeCode,
        );
      }
      if (e.message.contains('office_suspended')) {
        throw const DashboardAuthFailure(
          'تم إيقاف هذا المكتب. تواصل مع إدارة المنصة.',
        );
      }
      throw const DashboardAuthFailure('تعذر تحميل بيانات المكتب.');
    } catch (_) {
      throw const DashboardAuthFailure('تعذر تحميل بيانات المكتب.');
    }

    if (result is! Map) {
      throw const DashboardAuthFailure('تعذر تحميل بيانات المكتب.');
    }
    return OfficeContext.fromRpc(Map<String, dynamic>.from(result));
  }

  /// The one context failure that a pending self-registration can still fix.
  static const _noOfficeCode = 'not_an_office_user';

  @override
  Future<void> signOut() => _supabase.auth.signOut();

  @override
  bool get hasCachedSession => _supabase.auth.currentSession != null;
}

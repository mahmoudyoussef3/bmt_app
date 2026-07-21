import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/office_context.dart';

/// Dashboard authentication: **name + password, nothing else.**
///
/// Supabase Auth signs in with an email internally, so [signIn] first maps the typed
/// name to that account's login address via `resolve_office_user_login` — the same
/// indirection `resolve_captain_login` already uses for phone numbers, so the codebase
/// keeps one pattern rather than two. The address never surfaces in the UI.
class DashboardAuthDatasource {
  const DashboardAuthDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// Signs in and returns the operator's office context in one flow.
  ///
  /// Throws [DashboardAuthFailure] with a user-facing Arabic message on every
  /// failure path.
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
      // Deliberately the same message as an unknown name: distinguishing them would
      // turn this screen into a directory of who works here.
      throw const DashboardAuthFailure('اسم المستخدم أو كلمة المرور غير صحيحة.');
    } catch (_) {
      throw const DashboardAuthFailure('تعذر تسجيل الدخول. حاول مرة أخرى.');
    }

    try {
      return await loadContext();
    } catch (e) {
      // A valid password on an account with no active office is not a session.
      await signOut();
      rethrow;
    }
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
      throw const DashboardAuthFailure('اسم المستخدم أو كلمة المرور غير صحيحة.');
    }
    return map['login_email'] as String;
  }

  /// Loads the office context for the current session. Called after sign-in and on
  /// app start when a cached Supabase session already exists.
  Future<OfficeContext> loadContext() async {
    final Object? result;
    try {
      result = await _supabase.rpc('current_office_context');
    } on PostgrestException catch (e) {
      throw DashboardAuthFailure(_contextMessage(e.message));
    } catch (_) {
      throw const DashboardAuthFailure('تعذر تحميل بيانات المكتب.');
    }

    if (result is! Map) {
      throw const DashboardAuthFailure('تعذر تحميل بيانات المكتب.');
    }
    return OfficeContext.fromRpc(Map<String, dynamic>.from(result));
  }

  String _contextMessage(String raw) {
    if (raw.contains('not_an_office_user')) {
      return 'هذا الحساب غير مرتبط بأي مكتب. تواصل مع المسؤول.';
    }
    if (raw.contains('office_suspended')) {
      return 'تم إيقاف هذا المكتب. تواصل مع إدارة المنصة.';
    }
    return 'تعذر تحميل بيانات المكتب.';
  }

  Future<void> signOut() => _supabase.auth.signOut();

  bool get hasCachedSession => _supabase.auth.currentSession != null;
}

class DashboardAuthFailure implements Exception {
  const DashboardAuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

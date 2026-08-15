import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/staff_account.dart';
import '../../domain/repositories/users_repository.dart';

/// Dashboard staff directory, scoped to the signed-in operator's office.
///
/// The source of truth moved from `user_roles` (a flat, platform-wide table where any
/// admin could re-role or delete anyone) to `office_users`. `get_dashboard_users`
/// resolves the caller's office server-side, so there is no office parameter here to
/// tamper with, and every write is additionally constrained by RLS.
///
/// Every mutation goes through an RPC rather than a direct table write. RLS would allow
/// the writes — `office_users_admin_manage` covers them — but a policy sees one row at
/// a time and cannot express the rule that actually matters: an office must never be
/// left without an active owner. Those rules live in
/// `20260815100000_office_staff_provisioning.sql`.
///
/// Creating an account and resetting a password additionally need the Auth Admin API,
/// which needs the service-role key, which must never exist in a Flutter binary. Both
/// go through the `office-manage-user` Edge Function; the membership it writes is still
/// written under *this* session's JWT, so the Dashboard gains no authority through it.
class SupabaseUsersDatasource implements UsersRepository {
  const SupabaseUsersDatasource(this._client);

  final SupabaseClient _client;

  static const _manageFunction = 'office-manage-user';

  @override
  Future<List<AppUser>> getUsers() async {
    final rows = await _client.rpc('get_dashboard_users') as List;
    return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<StaffCredentials> createUser(StaffAccountRequest request) async {
    final data = await _invokeManage(request.toPayload());
    return StaffCredentials(
      username:
          data['login_username']?.toString() ??
          request.username.trim().toLowerCase(),
      temporaryPassword: _nullIfBlank(data['temporary_password']?.toString()),
    );
  }

  @override
  Future<StaffCredentials> resetPassword({
    required String officeUserId,
    String password = '',
  }) async {
    final data = await _invokeManage({
      'action': 'reset_password',
      'office_user_id': officeUserId,
      if (password.isNotEmpty) 'password': password,
    });
    return StaffCredentials(
      username: data['login_username']?.toString() ?? '',
      temporaryPassword: _nullIfBlank(data['temporary_password']?.toString()),
      isReset: true,
    );
  }

  @override
  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role) async {
    return _staffRpc('office_update_staff_role', {
      'p_office_user_id': userRoleId,
      'p_role': role.dbValue,
    });
  }

  @override
  Future<AppUser> setUserStatus(
    String userRoleId, {
    required bool active,
  }) async {
    return _staffRpc('office_set_staff_status', {
      'p_office_user_id': userRoleId,
      'p_status': active ? 'active' : 'disabled',
    });
  }

  @override
  Future<DashboardRole?> getCurrentUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('office_users')
        .select('role')
        .eq('user_id', uid)
        .eq('status', 'active')
        .limit(1);
    if (rows.isEmpty) return null;
    return DashboardRole.fromDb(rows.first['role'] as String);
  }

  /// The two RPCs that return a staff row, sharing one error translation.
  ///
  /// [LicensingGuard.check] runs first: a quota or read-only refusal carries the whole
  /// verdict and belongs on the upgrade card, not in a generic error string.
  Future<AppUser> _staffRpc(String name, Map<String, dynamic> params) async {
    try {
      final row = await _client.rpc(name, params: params);
      if (row is! Map) {
        throw Exception('تعذر تحديث بيانات المستخدم.');
      }
      return _fromRow(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      LicensingGuard.check(error);
      throw Exception(_messageForCode(error.message));
    }
  }

  /// Calls the Edge Function and unwraps its body.
  ///
  /// The function answers a failure two ways depending on how it failed — a thrown
  /// [FunctionException] for a non-2xx status, or a 200 body carrying an `error` key —
  /// so both are folded into the same handling here.
  Future<Map<String, dynamic>> _invokeManage(Map<String, dynamic> body) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(_manageFunction, body: body);
    } on FunctionException catch (error) {
      _throwForBody(error.details);
    } catch (_) {
      throw Exception('تعذر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.');
    }

    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    if ((data['error']?.toString().trim() ?? '').isNotEmpty) {
      _throwForBody(data);
    }
    return data;
  }

  /// Turns an Edge Function error body into the same failure a direct RPC would raise.
  ///
  /// The function forwards Postgres' `DETAIL:` payload verbatim, so a licensing refusal
  /// that travelled through it still carries its verdict (plan, limit, used). Rebuilding
  /// a [PostgrestException] around the pair is what lets [LicensingGuard] recognise it
  /// and raise the upgrade card — without this the quota that actually stops an office
  /// adding a ninth operator would read as a generic failure.
  Never _throwForBody(dynamic details) {
    final map = details is Map
        ? Map<String, dynamic>.from(details)
        : const <String, dynamic>{};
    final code = map['error']?.toString().trim() ?? details?.toString() ?? '';

    LicensingGuard.check(
      PostgrestException(message: code, details: map['detail']),
    );
    throw Exception(_messageForCode(code));
  }

  /// Server errors are machine codes by design — `raise exception 'username_taken'` and
  /// the Edge Function's own vocabulary — so the Arabic text lives here, once, rather
  /// than being duplicated across a SQL function and a Deno file that neither can
  /// localise.
  String _messageForCode(String raw) {
    final code = raw.trim();
    if (code.contains('dashboard_admin_required')) {
      return 'إدارة المستخدمين متاحة لمالك المكتب فقط.';
    }
    if (code.contains('not_an_office_user')) {
      return 'هذا الحساب غير مرتبط بأي مكتب.';
    }
    if (code.contains('not_authenticated')) {
      return 'انتهت الجلسة. سجّل الدخول مرة أخرى.';
    }
    if (code.contains('username_taken')) {
      return 'اسم الدخول مستخدم بالفعل. اختر اسماً آخر.';
    }
    if (code.contains('invalid_username')) {
      return 'اسم الدخول غير صالح — حروف إنجليزية صغيرة وأرقام و . _ - فقط.';
    }
    if (code.contains('invalid_full_name')) {
      return 'اسم الموظف طويل جداً.';
    }
    if (code.contains('weak_password')) {
      return 'كلمة المرور 10 أحرف على الأقل.';
    }
    if (code.contains('invalid_role')) {
      return 'الدور المحدد غير صالح.';
    }
    if (code.contains('cannot_change_own_role')) {
      return 'لا يمكنك تغيير دورك بنفسك. اطلب ذلك من مالك آخر.';
    }
    if (code.contains('cannot_disable_self')) {
      return 'لا يمكنك تعطيل حسابك الحالي.';
    }
    if (code.contains('last_admin_required')) {
      return 'لا يمكن ترك المكتب بلا مالك نشط. عيّن مالكاً آخر أولاً.';
    }
    if (code.contains('staff_user_already_assigned')) {
      return 'هذا الحساب مرتبط بمكتب آخر بالفعل.';
    }
    if (code.contains('staff_not_found') ||
        code.contains('staff_user_not_found')) {
      return 'لم يعد هذا المستخدم موجوداً. حدّث القائمة.';
    }
    if (code.contains('auth_user_creation_failed')) {
      return 'تعذر إنشاء حساب الدخول. حاول مرة أخرى.';
    }
    if (code.contains('password_reset_failed')) {
      return 'تعذر تغيير كلمة المرور. حاول مرة أخرى.';
    }
    return 'تعذر تنفيذ العملية. حاول مرة أخرى.';
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  AppUser _fromRow(Map<String, dynamic> r) {
    return AppUser(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      username: (r['username'] as String?) ?? '',
      fullName: (r['full_name'] as String?) ?? '',
      status: (r['status'] as String?) ?? 'active',
      email: r['email'] as String?,
      role: DashboardRole.fromDb(r['role'] as String? ?? 'support_agent'),
      createdAt: DateTime.parse(
        r['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

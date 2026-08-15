import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';

/// Everything needed to give a colleague a dashboard login.
///
/// Deliberately holds no `officeId` and no `status`: both are decided by
/// `office_create_staff` from the caller's own session, never sent. A request object
/// that *could* carry an office id would be a request object someone eventually
/// populates — and it is the one value on this wire worth tampering with.
///
/// There is no email field either. Dashboard login is name + password; the synthetic
/// address behind the name is derived server-side and never typed by anyone.
class StaffAccountRequest {
  const StaffAccountRequest({
    required this.username,
    this.fullName = '',
    this.role = DashboardRole.supportAgent,
    this.password = '',
  });

  /// The login name this colleague will type. Unique across the whole platform, not
  /// just this office — `uq_office_users_username` is a global index — so a taken name
  /// is a normal outcome rather than a surprise.
  final String username;

  final String fullName;

  /// Defaults to the least privileged role. An unset role must never mean owner.
  final DashboardRole role;

  /// Blank means "generate one", and the generated value comes back exactly once in the
  /// response. Never stored, never logged, never retrievable later.
  final String password;

  static final _usernamePattern = RegExp(r'^[a-z0-9][a-z0-9._-]*$');

  /// Field-keyed validation errors, empty when the request is sendable.
  ///
  /// The same rules run again in the Edge Function and a third time inside
  /// `office_create_staff`. That is not redundancy for its own sake: the RPC is
  /// directly callable by any office owner, so it cannot trust either layer above it,
  /// and this copy exists so the form can mark the offending field rather than show a
  /// server error with no anchor.
  Map<String, String> validate() {
    final errors = <String, String>{};

    final trimmedUsername = username.trim().toLowerCase();
    if (trimmedUsername.length < 3 || trimmedUsername.length > 32) {
      errors['username'] = 'اسم الدخول مطلوب (3 إلى 32 حرفاً)';
    } else if (!_usernamePattern.hasMatch(trimmedUsername)) {
      errors['username'] = 'حروف إنجليزية صغيرة وأرقام و . _ - فقط';
    }

    if (fullName.trim().length > 120) {
      errors['fullName'] = 'الاسم طويل جداً';
    }

    if (password.isNotEmpty && password.length < 10) {
      errors['password'] = 'كلمة المرور 10 أحرف على الأقل';
    }

    return errors;
  }

  /// The wire payload. A blank password is omitted rather than sent as an empty string,
  /// so the server's "generate one" and "use this one" branches stay distinguishable.
  Map<String, dynamic> toPayload() => {
    'action': 'create',
    'username': username.trim().toLowerCase(),
    'role': role.dbValue,
    if (fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
    if (password.isNotEmpty) 'password': password,
  };
}

/// What creating or resetting an account returns — shown once, then unrecoverable.
///
/// [temporaryPassword] is null when the owner chose the password themselves; the server
/// does not echo a secret it was handed. When it is present it exists nowhere else: not
/// in a log, not in a table, not behind any later screen.
class StaffCredentials {
  const StaffCredentials({
    required this.username,
    this.temporaryPassword,
    this.isReset = false,
  });

  final String username;
  final String? temporaryPassword;

  /// Whether this is a password reset rather than a new account, so the reveal can say
  /// which one happened. The two are otherwise identical: one login name, one secret
  /// that will not be shown again.
  final bool isReset;

  bool get hasTemporaryPassword => (temporaryPassword ?? '').isNotEmpty;
}

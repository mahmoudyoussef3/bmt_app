import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';

/// One member of the signed-in office's dashboard staff.
///
/// [id] is the `office_users` row — the *membership*, which is what every action names.
/// [userId] is the auth account behind it. They are deliberately separate: the same
/// person could in principle be re-provisioned, and every server-side rule
/// ("is this row in my office?", "is this the last owner?") is a statement about the
/// membership, not about the login.
class AppUser {
  const AppUser({
    required this.id,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.username = '',
    this.fullName = '',
    this.status = 'active',
    this.email,
  });

  final String id;
  final String userId;
  final DashboardRole role;
  final DateTime createdAt;

  /// What this operator types into the sign-in screen. The login *name* — never an
  /// address: the synthetic `@office.ewt.internal` one in [email] exists only because
  /// Supabase Auth needs an email internally, and nobody ever types or reads it.
  final String username;

  final String fullName;

  /// `active` or `disabled`. A disabled operator is refused at sign-in by
  /// `resolve_office_user_login`, and their row stays for the audit trail.
  final String status;

  final String? email;

  bool get isActive => status == 'active';

  /// Best available human label: the person's name, else their login name, else the
  /// leading fragment of the account id — which is all that existed before staff
  /// provisioning recorded the other two.
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return email ?? userId.substring(0, 8);
  }

  AppUser copyWith({DashboardRole? role, String? status, String? email}) {
    return AppUser(
      id: id,
      userId: userId,
      role: role ?? this.role,
      createdAt: createdAt,
      username: username,
      fullName: fullName,
      status: status ?? this.status,
      email: email ?? this.email,
    );
  }
}

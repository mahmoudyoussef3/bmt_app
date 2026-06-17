import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.email,
  });

  final String id;
  final String userId;
  final DashboardRole role;
  final DateTime createdAt;
  final String? email;

  String get displayName => email ?? userId.substring(0, 8);

  AppUser copyWith({DashboardRole? role, String? email}) {
    return AppUser(
      id: id,
      userId: userId,
      role: role ?? this.role,
      createdAt: createdAt,
      email: email ?? this.email,
    );
  }
}

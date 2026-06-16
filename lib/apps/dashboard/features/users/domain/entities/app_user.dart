import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DashboardRole role;
  final DateTime createdAt;

  AppUser copyWith({DashboardRole? role}) {
    return AppUser(
      id: id,
      userId: userId,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}

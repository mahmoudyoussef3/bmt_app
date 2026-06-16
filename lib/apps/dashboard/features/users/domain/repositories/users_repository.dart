import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import '../entities/app_user.dart';

abstract class UsersRepository {
  Future<List<AppUser>> getUsers();
  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role);
  Future<void> removeUser(String userRoleId);
  Future<DashboardRole?> getCurrentUserRole();
}

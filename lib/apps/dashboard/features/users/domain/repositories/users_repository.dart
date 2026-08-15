import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import '../entities/app_user.dart';
import '../entities/staff_account.dart';

abstract class UsersRepository {
  Future<List<AppUser>> getUsers();

  /// Creates the login account AND its membership in the caller's office.
  Future<StaffCredentials> createUser(StaffAccountRequest request);

  /// Issues a new password for an existing staff account. [officeUserId] is the
  /// `office_users` row id — the membership, which is the only thing the server will
  /// accept as a target.
  Future<StaffCredentials> resetPassword({
    required String officeUserId,
    String password = '',
  });

  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role);

  /// Disables or re-enables an account. There is no delete: see
  /// `20260815100000_office_staff_provisioning.sql` for why removal is a status change.
  Future<AppUser> setUserStatus(String userRoleId, {required bool active});

  Future<DashboardRole?> getCurrentUserRole();
}

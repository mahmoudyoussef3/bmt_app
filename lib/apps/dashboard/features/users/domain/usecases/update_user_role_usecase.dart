import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import '../entities/app_user.dart';
import '../repositories/users_repository.dart';

class UpdateUserRoleUseCase {
  const UpdateUserRoleUseCase(this._repository);

  final UsersRepository _repository;

  Future<AppUser> call(String userRoleId, DashboardRole role) =>
      _repository.updateUserRole(userRoleId, role);
}

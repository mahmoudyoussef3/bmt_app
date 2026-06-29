import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import '../repositories/users_repository.dart';

class GetCurrentUserRoleUseCase {
  const GetCurrentUserRoleUseCase(this._repository);

  final UsersRepository _repository;

  Future<DashboardRole?> call() => _repository.getCurrentUserRole();
}

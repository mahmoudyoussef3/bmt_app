import '../entities/app_user.dart';
import '../repositories/users_repository.dart';

class SetDashboardUserStatusUseCase {
  const SetDashboardUserStatusUseCase(this._repository);

  final UsersRepository _repository;

  Future<AppUser> call(String userRoleId, {required bool active}) =>
      _repository.setUserStatus(userRoleId, active: active);
}

import '../entities/staff_account.dart';
import '../repositories/users_repository.dart';

class ResetDashboardUserPasswordUseCase {
  const ResetDashboardUserPasswordUseCase(this._repository);

  final UsersRepository _repository;

  Future<StaffCredentials> call(String officeUserId, {String password = ''}) =>
      _repository.resetPassword(officeUserId: officeUserId, password: password);
}

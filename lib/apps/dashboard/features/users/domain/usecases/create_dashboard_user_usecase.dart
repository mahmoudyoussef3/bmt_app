import '../entities/staff_account.dart';
import '../repositories/users_repository.dart';

class CreateDashboardUserUseCase {
  const CreateDashboardUserUseCase(this._repository);

  final UsersRepository _repository;

  Future<StaffCredentials> call(StaffAccountRequest request) =>
      _repository.createUser(request);
}

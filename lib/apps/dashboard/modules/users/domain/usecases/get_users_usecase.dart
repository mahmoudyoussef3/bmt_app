import '../entities/app_user.dart';
import '../repositories/users_repository.dart';

class GetUsersUseCase {
  const GetUsersUseCase(this._repository);

  final UsersRepository _repository;

  Future<List<AppUser>> call() => _repository.getUsers();
}

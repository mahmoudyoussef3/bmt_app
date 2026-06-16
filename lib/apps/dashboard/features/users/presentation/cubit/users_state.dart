import '../../domain/entities/app_user.dart';

sealed class UsersState {
  const UsersState();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  const UsersLoaded(this.users);

  final List<AppUser> users;
}

class UsersError extends UsersState {
  const UsersError(this.message);

  final String message;
}

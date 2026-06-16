import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/update_user_role_usecase.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit({
    required GetUsersUseCase getUsers,
    required UpdateUserRoleUseCase updateRole,
  }) : _getUsers = getUsers,
       _updateRole = updateRole,
       super(const UsersLoading());

  final GetUsersUseCase _getUsers;
  final UpdateUserRoleUseCase _updateRole;

  Future<void> load() async {
    emit(const UsersLoading());
    try {
      emit(UsersLoaded(await _getUsers()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> changeRole(String userRoleId, DashboardRole role) async {
    final current = state;
    if (current is! UsersLoaded) return;
    try {
      final updated = await _updateRole(userRoleId, role);
      final users = current.users
          .map((u) => u.id == userRoleId ? updated : u)
          .toList();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> removeUser(AppUser user) async {
    final current = state;
    if (current is! UsersLoaded) return;
    try {
      emit(UsersLoaded(
        current.users.where((u) => u.id != user.id).toList(),
      ));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}

import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/users_repository.dart';

class SupabaseUsersDatasource implements UsersRepository {
  const SupabaseUsersDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppUser>> getUsers() async {
    try {
      final rows = await _client.rpc('get_dashboard_users') as List;
      return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback if migration_12 hasn't been run yet
      final rows = await _client
          .from('user_roles')
          .select()
          .not('role', 'eq', 'client')
          .order('created_at', ascending: false);
      return rows.map(_fromRow).toList();
    }
  }

  @override
  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role) async {
    final rows = await _client
        .from('user_roles')
        .update({'role': role.dbValue})
        .eq('id', userRoleId)
        .select();
    return _fromRow(rows.first);
  }

  @override
  Future<void> removeUser(String userRoleId) async {
    await _client.from('user_roles').delete().eq('id', userRoleId);
  }

  @override
  Future<DashboardRole?> getCurrentUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', uid)
        .not('role', 'eq', 'client')
        .limit(1);
    if (rows.isEmpty) return null;
    return DashboardRole.fromDb(rows.first['role'] as String);
  }

  AppUser _fromRow(Map<String, dynamic> r) {
    return AppUser(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      email: r['email'] as String?,
      role: DashboardRole.fromDb(r['role'] as String? ?? 'support_agent'),
      createdAt: DateTime.parse(
        r['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

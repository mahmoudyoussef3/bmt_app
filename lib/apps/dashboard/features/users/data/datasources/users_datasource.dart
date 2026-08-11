import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/users_repository.dart';

/// Dashboard staff directory, scoped to the signed-in operator's office.
///
/// The source of truth moved from `user_roles` (a flat, platform-wide table where any
/// admin could re-role or delete anyone) to `office_users`. `get_dashboard_users`
/// resolves the caller's office server-side, so there is no office parameter here to
/// tamper with, and every write is additionally constrained by RLS.
class SupabaseUsersDatasource implements UsersRepository {
  const SupabaseUsersDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppUser>> getUsers() async {
    final rows = await _client.rpc('get_dashboard_users') as List;
    return rows.map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<AppUser> updateUserRole(String userRoleId, DashboardRole role) async {
    final rows = await LicensingGuard.run(
      () => _client
          .from('office_users')
          .update({'role': role.dbValue})
          .eq('id', userRoleId)
          .select('id, user_id, username, full_name, role, status, created_at'),
    );
    return _fromRow(rows.first);
  }

  @override
  Future<void> removeUser(String userRoleId) async {
    await LicensingGuard.run(
      () => _client.from('office_users').delete().eq('id', userRoleId),
    );
  }

  @override
  Future<DashboardRole?> getCurrentUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('office_users')
        .select('role')
        .eq('user_id', uid)
        .eq('status', 'active')
        .limit(1);
    if (rows.isEmpty) return null;
    return DashboardRole.fromDb(rows.first['role'] as String);
  }

  AppUser _fromRow(Map<String, dynamic> r) {
    
    final email = (r['email'] as String?) ?? (r['username'] as String?);
    return AppUser(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      email: email,
      role: DashboardRole.fromDb(r['role'] as String? ?? 'support_agent'),
      createdAt: DateTime.parse(
        r['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

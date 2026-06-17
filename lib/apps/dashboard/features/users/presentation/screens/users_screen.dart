import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => dashboardDi<UsersCubit>()..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        if (state is UsersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is UsersError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                const SizedBox(height: 12),
                AppButton(
                  label: 'إعادة المحاولة',
                  onPressed: () => context.read<UsersCubit>().load(),
                ),
              ],
            ),
          );
        }
        final users = (state as UsersLoaded).users;
        if (users.isEmpty) {
          return const Center(
            child: Text('لا يوجد مستخدمون مسجلون بعد'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          separatorBuilder: (_, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = users[index];
            return AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      user.displayName.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email ?? user.userId,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (user.email != null)
                          Text(
                            user.userId,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          'منذ ${_formatDate(user.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<DashboardRole>(
                    value: user.role,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: DashboardRole.values
                        .where((r) => r != DashboardRole.admin ||
                            user.role == DashboardRole.admin)
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label),
                          ),
                        )
                        .toList(),
                    onChanged: (role) {
                      if (role != null && role != user.role) {
                        context.read<UsersCubit>().changeRole(user.id, role);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'إزالة الصلاحية',
                    icon: const Icon(Icons.person_remove_outlined),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _confirmRemove(context, user.userId,
                        () => context.read<UsersCubit>().removeUser(user)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String userId,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إزالة الصلاحية'),
        content: Text('هل تريد إزالة صلاحيات المستخدم $userId؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'إزالة',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays} يوم';
    if (diff.inHours > 0) return '${diff.inHours} ساعة';
    return 'الآن';
  }
}

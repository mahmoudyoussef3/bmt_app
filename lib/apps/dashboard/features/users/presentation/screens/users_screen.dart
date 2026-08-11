import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

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

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  String _query = '';
  DashboardRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        if (state is UsersLoading) {
          return const DashboardLoading();
        }
        if (state is UsersError) {
          return DashboardErrorState(
            message: state.message,
            onRetry: () => context.read<UsersCubit>().load(),
          );
        }
        final users = (state as UsersLoaded).users;
        final filtered = _filterUsers(users);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            DashboardModuleHeader(
              icon: DashboardIcons.usersActive,
              title: 'المستخدمون والصلاحيات',
              subtitle: 'إدارة مستخدمي لوحة التحكم وأدوار خدمة العملاء.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.read<UsersCubit>().load(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تحديث'),
                ),
              ],
              
              child: DashboardCollapsibleSection.bare(
                sectionId: DashboardSectionIds.usersFilters,
                icon: Icons.filter_alt_outlined,
                title: 'البحث والتصفية',
                headerPadding: EdgeInsets.zero,
                bodyPadding: const EdgeInsets.only(top: AppSpacing.medium),
                collapsedSummary: DashboardSectionSummary(
                  items: [
                    if (_query.trim().isNotEmpty) 'بحث: ${_query.trim()}',
                    if (_roleFilter != null) _roleFilter!.label,
                    '${filtered.length}/${users.length} مستخدم',
                  ],
                ),
                child: _UsersToolbar(
                  users: users,
                  filteredCount: filtered.length,
                  query: _query,
                  roleFilter: _roleFilter,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onRoleChanged: (role) => setState(() => _roleFilter = role),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            if (users.isEmpty)
              const EmptyState(
                title: 'لا يوجد مستخدمون مسجلون بعد',
                subtitle: 'ستظهر هنا حسابات لوحة التحكم بعد منح الصلاحيات.',
              )
            else if (filtered.isEmpty)
              const EmptyState(
                title: 'لا توجد نتائج مطابقة',
                subtitle: 'غيّر البحث أو فلتر الدور لعرض مستخدمين آخرين.',
              )
            else
              ...filtered.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: _UserAccessRow(
                    user: user,
                    onRoleChanged: (role) {
                      if (role != user.role) {
                        context.read<UsersCubit>().changeRole(user.id, role);
                      }
                    },
                    onRemove: () => _confirmRemove(
                      context,
                      user.userId,
                      () => context.read<UsersCubit>().removeUser(user),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    final query = _query.trim().toLowerCase();
    return users.where((user) {
      final matchesQuery =
          query.isEmpty ||
          user.userId.toLowerCase().contains(query) ||
          (user.email ?? '').toLowerCase().contains(query) ||
          user.role.label.contains(query);
      final matchesRole = _roleFilter == null || user.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
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
}

class _UsersToolbar extends StatelessWidget {
  final List<AppUser> users;
  final int filteredCount;
  final String query;
  final DashboardRole? roleFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DashboardRole?> onRoleChanged;

  const _UsersToolbar({
    required this.users,
    required this.filteredCount,
    required this.query,
    required this.roleFilter,
    required this.onQueryChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = DebouncedSearchField(
          hintText: 'بحث بالبريد أو معرف المستخدم أو الدور...',
          initialValue: query,
          onChanged: onQueryChanged,
        );
        final filter = DropdownButtonFormField<DashboardRole?>(
          initialValue: roleFilter,
          decoration: const InputDecoration(labelText: 'الدور'),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الأدوار')),
            ...DashboardRole.values.map(
              (role) => DropdownMenuItem(value: role, child: Text(role.label)),
            ),
          ],
          onChanged: onRoleChanged,
        );
        final chip = StatusChip(label: '$filteredCount/${users.length} مستخدم');
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.small),
              filter,
              const SizedBox(height: AppSpacing.small),
              Align(alignment: AlignmentDirectional.centerStart, child: chip),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: AppSpacing.medium),
            SizedBox(width: 220, child: filter),
            const SizedBox(width: AppSpacing.medium),
            chip,
          ],
        );
      },
    );
  }
}

class _UserAccessRow extends StatelessWidget {
  final AppUser user;
  final ValueChanged<DashboardRole> onRoleChanged;
  final VoidCallback onRemove;

  const _UserAccessRow({
    required this.user,
    required this.onRoleChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = user.displayName.isEmpty
        ? '--'
        : user.displayName.characters.take(2).toString().toUpperCase();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email ?? user.userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (user.email != null)
                  Text(
                    user.userId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  'منذ ${_formatRelativeDate(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          DropdownButton<DashboardRole>(
            value: user.role,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: DashboardRole.values
                .where(
                  (role) =>
                      role != DashboardRole.admin ||
                      user.role == DashboardRole.admin,
                )
                .map(
                  (role) =>
                      DropdownMenuItem(value: role, child: Text(role.label)),
                )
                .toList(),
            onChanged: (role) {
              if (role != null) onRoleChanged(role);
            },
          ),
          const SizedBox(width: AppSpacing.xSmall),
          IconButton(
            tooltip: 'إزالة الصلاحية',
            icon: const Icon(Icons.person_remove_outlined),
            color: scheme.error,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

String _formatRelativeDate(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
  if (diff.inDays > 0) return '${diff.inDays} يوم';
  if (diff.inHours > 0) return '${diff.inHours} ساعة';
  return 'الآن';
}

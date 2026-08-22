import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/session/dashboard_session.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
import '../widgets/staff_account_dialog.dart';
import '../widgets/staff_credentials_panel.dart';
import '../widgets/staff_password_dialog.dart';
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

  /// The signed-in operator's own login name, so their row can refuse the two actions
  /// the server will refuse anyway — changing their own role, disabling themselves.
  /// Showing live controls that are guaranteed to fail is worse than not showing them.
  ///
  /// Matched on the username rather than the auth id because that is what the session
  /// context carries, and `uq_office_users_username` makes it unique across the whole
  /// platform — so it identifies exactly one row.
  String? get _selfUsername {
    final username = dashboardDi<DashboardSession>().context?.username.trim();
    return (username == null || username.isEmpty) ? null : username;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      // Action outcomes are notices over the screen, never replacements for it: a
      // refused role change must leave the directory exactly where it was.
      listenWhen: (_, current) =>
          current is UsersActionSuccess || current is UsersActionFailure,
      listener: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        final (message, isError) = switch (state) {
          UsersActionSuccess(:final message) => (message, false),
          UsersActionFailure(:final message) => (message, true),
          _ => ('', false),
        };
        if (message.isEmpty) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? scheme.errorContainer : null,
            ),
          );
      },
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
        if (state is UsersCredentialsIssued) {
          return StaffCredentialsPanel(
            credentials: state.credentials,
            onDone: context.read<UsersCubit>().acknowledgeCredentials,
          );
        }

        final users = switch (state) {
          UsersLoaded(:final users) => users,
          UsersActionSuccess(:final users) => users,
          UsersActionFailure(:final users) => users,
          _ => const <AppUser>[],
        };
        final filtered = _filterUsers(users);
        final selfUsername = _selfUsername;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            DashboardModuleHeader(
              icon: DashboardIcons.usersActive,
              title: 'المستخدمون والصلاحيات',
              subtitle:
                  'حسابات لوحة التحكم الخاصة بمكتبك — أنشئ حساباً لكل موظف '
                  'وحدّد ما يراه.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.read<UsersCubit>().load(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تحديث'),
                ),
                FilledButton.icon(
                  onPressed: () => showStaffAccountDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('إضافة مستخدم'),
                ),
              ],

              pinned: DashboardCollapsibleSection.bare(
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
                subtitle:
                    'أضف حساباً لكل موظف يحتاج الدخول إلى لوحة التحكم، وحدّد '
                    'دوره عند الإنشاء.',
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
                    isSelf: selfUsername != null &&
                        user.username.toLowerCase() ==
                            selfUsername.toLowerCase(),
                    onRoleChanged: (role) {
                      if (role != user.role) {
                        context.read<UsersCubit>().changeRole(user.id, role);
                      }
                    },
                    onResetPassword: () => _resetPassword(context, user),
                    onToggleActive: () => _confirmToggle(context, user),
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
          user.username.toLowerCase().contains(query) ||
          user.fullName.toLowerCase().contains(query) ||
          (user.email ?? '').toLowerCase().contains(query) ||
          user.role.label.contains(query);
      final matchesRole = _roleFilter == null || user.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
  }

  Future<void> _resetPassword(BuildContext context, AppUser user) async {
    final cubit = context.read<UsersCubit>();
    final password = await showStaffPasswordDialog(
      context,
      username: user.username.isEmpty ? user.displayName : user.username,
    );
    // Null is a cancellation; an empty string is "generate one server-side".
    if (password == null) return;
    await cubit.resetPassword(user, password: password);
  }

  Future<void> _confirmToggle(BuildContext context, AppUser user) async {
    final cubit = context.read<UsersCubit>();
    final name = user.displayName;

    if (user.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تعطيل الحساب'),
          content: Text(
            'لن يتمكن «$name» من تسجيل الدخول بعد الآن. يمكنك إعادة تفعيل '
            'الحساب في أي وقت.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'تعطيل',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await cubit.setActive(user, active: !user.isActive);
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
          hintText: 'بحث بالاسم أو اسم الدخول أو الدور...',
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
        final chip = DashboardStatusChip(label: '$filteredCount/${users.length} مستخدم');
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

  /// The signed-in owner's own row. Their role picker and disable action are inert,
  /// because `office_update_staff_role` and `office_set_staff_status` refuse both —
  /// an office that could demote its last owner would have nobody left to undo it.
  final bool isSelf;

  final ValueChanged<DashboardRole> onRoleChanged;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleActive;

  const _UserAccessRow({
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
    required this.onResetPassword,
    required this.onToggleActive,
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
            backgroundColor: user.isActive
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            child: Text(
              initials,
              style: TextStyle(
                color: user.isActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: AppSpacing.xSmall),
                      Text(
                        '(أنت)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (user.username.isNotEmpty)
                  Text(
                    user.username,
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
          if (!user.isActive) ...[
            const SizedBox(width: AppSpacing.small),
            DashboardStatusChip(
              label: 'معطّل',
              color: scheme.errorContainer.withAlpha(70),
              textColor: scheme.error,
            ),
          ],
          const SizedBox(width: AppSpacing.small),
          DropdownButton<DashboardRole>(
            value: user.role,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: DashboardRole.values
                .map(
                  (role) =>
                      DropdownMenuItem(value: role, child: Text(role.label)),
                )
                .toList(),
            onChanged: isSelf
                ? null
                : (role) {
                    if (role != null) onRoleChanged(role);
                  },
          ),
          const SizedBox(width: AppSpacing.xSmall),
          PopupMenuButton<_UserAction>(
            tooltip: 'إجراءات',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => switch (action) {
              _UserAction.resetPassword => onResetPassword(),
              _UserAction.toggleActive => onToggleActive(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _UserAction.resetPassword,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.key_outlined),
                  title: Text('تعيين كلمة مرور جديدة'),
                ),
              ),
              PopupMenuItem(
                value: _UserAction.toggleActive,
                // Disabling yourself locks you out of the screen that could undo it.
                enabled: !isSelf,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    user.isActive
                        ? Icons.person_off_outlined
                        : Icons.person_add_alt_rounded,
                    color: user.isActive ? scheme.error : null,
                  ),
                  title: Text(user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _UserAction { resetPassword, toggleActive }

String _formatRelativeDate(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
  if (diff.inDays > 0) return '${diff.inDays} يوم';
  if (diff.inHours > 0) return '${diff.inHours} ساعة';
  return 'الآن';
}

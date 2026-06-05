import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'core/di/di.dart' as di;
import 'domain/repositories/support_ticket_repository.dart';
import 'presentation/cubit/support_ticket_cubit.dart';
import 'presentation/cubit/kpi_cubit.dart';
import 'domain/repositories/kpi_repository.dart';
import 'domain/repositories/trip_stream_repository.dart';
import 'domain/repositories/driver_stream_repository.dart';
import 'core/eventbus/live_event_bus.dart';
import 'presentation/cubit/live_ops_cubit.dart';
import 'presentation/pages/support_ticket_list_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/booking_management_page.dart';
import 'presentation/pages/customer_management_page.dart';
import 'presentation/pages/payment_review_page.dart';
import 'presentation/pages/trip_operations_page.dart';
import 'presentation/widgets/app_card.dart';

class OpsDashboardModule extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const OpsDashboardModule({
    this.themeMode = ThemeMode.dark,
    this.onThemeModeChanged = _ignoreThemeModeChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    di.registerOpsCenterDependencies();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SupportTicketCubit(di.di<SupportTicketRepository>()),
        ),
        BlocProvider(
          create: (_) => KpiCubit(di.di<KpiRepository>())..loadKpis(),
        ),
        BlocProvider(
          create: (_) => LiveOpsCubit(
            tripRepo: di.di<TripStreamRepository>(),
            driverRepo: di.di<DriverStreamRepository>(),
            eventBus: di.di<LiveEventBus>(),
          ),
        ),
      ],
      child: _OpsShell(
        themeMode: ThemeMode.dark,
        onThemeModeChanged: onThemeModeChanged,
      ),
    );
  }

  static void _ignoreThemeModeChange(ThemeMode mode) {}
}

enum _OpsRole {
  admin('المسؤول'),
  customerService('خدمة العملاء'),
  operationsSupervisor('مشرف التشغيل'),
  finance('المالية');

  final String label;

  const _OpsRole(this.label);
}

class _OpsShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const _OpsShell({required this.themeMode, required this.onThemeModeChanged});

  @override
  State<_OpsShell> createState() => _OpsShellState();
}

class _OpsShellState extends State<_OpsShell> {
  int _index = 0;
  _OpsRole _role = _OpsRole.customerService;

  late final List<_OpsNavItem> _items = [
    _OpsNavItem(
      label: 'الرئيسية',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      roles: _OpsRole.values.toSet(),
      pageBuilder: (role) => OpsHomePage(
        roleLabel: role.label,
        availableQuickActions: _quickActionsForRole(role),
      ),
    ),
    _OpsNavItem(
      label: 'الحجوزات',
      icon: Icons.event_seat_outlined,
      selectedIcon: Icons.event_seat_rounded,
      roles: const {_OpsRole.admin, _OpsRole.customerService},
      pageBuilder: (_) => const BookingManagementPage(showBackButton: false),
    ),
    _OpsNavItem(
      label: 'الرحلات',
      icon: Icons.route_outlined,
      selectedIcon: Icons.route_rounded,
      roles: const {
        _OpsRole.admin,
        _OpsRole.customerService,
        _OpsRole.operationsSupervisor,
      },
      pageBuilder: (_) => const TripOperationsPage(showBackButton: false),
    ),
    _OpsNavItem(
      label: 'العملاء',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      roles: const {_OpsRole.admin, _OpsRole.customerService},
      pageBuilder: (_) => const CustomerManagementPage(showBackButton: false),
    ),
    _OpsNavItem(
      label: 'الشكاوى',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
      roles: const {_OpsRole.admin, _OpsRole.customerService},
      pageBuilder: (_) => const SupportTicketListPage(),
    ),
    _OpsNavItem(
      label: 'المدفوعات',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
      roles: const {_OpsRole.admin, _OpsRole.customerService, _OpsRole.finance},
      pageBuilder: (_) => const PaymentReviewPage(showBackButton: false),
    ),
    _OpsNavItem(
      label: 'الاشتراكات',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
      roles: const {_OpsRole.admin, _OpsRole.customerService},
      pageBuilder: (_) => const _OperationsLandingPage(
        title: 'الاشتراكات',
        nextStep: 'راجع الاشتراكات التي تنتهي اليوم ثم تواصل مع العملاء.',
        tasks: ['تجديد اشتراك', 'تعديل باقة', 'مراجعة عميل'],
      ),
    ),
    _OpsNavItem(
      label: 'السائقون',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
      roles: const {_OpsRole.admin, _OpsRole.operationsSupervisor},
      pageBuilder: (_) => const _OperationsLandingPage(
        title: 'السائقون',
        nextStep: 'ابدأ بتأكيد توفر السائقين قبل إسناد الرحلات القادمة.',
        tasks: ['إضافة سائق', 'تعديل وردية', 'متابعة إسناد'],
      ),
    ),
    _OpsNavItem(
      label: 'التقارير',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      roles: const {_OpsRole.admin, _OpsRole.finance},
      pageBuilder: (_) => const _OperationsLandingPage(
        title: 'التقارير',
        nextStep: 'راجع ملخص اليوم قبل تصدير أي تقرير للإدارة.',
        tasks: ['تقرير يومي', 'تقرير مالي', 'تقرير شكاوى'],
      ),
    ),
    _OpsNavItem(
      label: 'الإعدادات',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      roles: const {_OpsRole.admin},
      pageBuilder: (_) => _SettingsPage(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleItems = _visibleItems;
    final selectedIndex = _index.clamp(0, visibleItems.length - 1);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _OpsMobileDrawer(
          items: visibleItems,
          role: _role,
          selectedIndex: selectedIndex,
          onRoleChanged: _setRole,
          onSelected: (i) {
            Navigator.of(context).pop();
            setState(() => _index = i);
          },
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final horizontalPadding = w < 900
                ? AppSpacing.medium
                : AppSpacing.xLarge;
            final verticalPadding = w < 900
                ? AppSpacing.small
                : AppSpacing.large;

            if (w < 860) {
              return _buildPageHost(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                items: visibleItems,
                selectedIndex: selectedIndex,
                showMenuButton: true,
              );
            }

            return Row(
              children: [
                _OpsSidebar(
                  items: visibleItems,
                  role: _role,
                  selectedIndex: selectedIndex,
                  onRoleChanged: _setRole,
                  onSelected: (i) => setState(() => _index = i),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                    child: _buildPageHost(
                      horizontalPadding: horizontalPadding,
                      verticalPadding: verticalPadding,
                      items: visibleItems,
                      selectedIndex: selectedIndex,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHost({
    required double horizontalPadding,
    required double verticalPadding,
    required List<_OpsNavItem> items,
    required int selectedIndex,
    bool showMenuButton = false,
  }) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showMenuButton) ...[
                  Builder(
                    builder: (context) => Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filledTonal(
                        tooltip: 'القائمة',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      );
                      return FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(fade),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>('${_role.name}-$selectedIndex'),
                      child: items[selectedIndex].pageBuilder(_role),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_OpsNavItem> get _visibleItems {
    return _items.where((item) => item.roles.contains(_role)).toList();
  }

  void _setRole(_OpsRole role) {
    setState(() {
      _role = role;
      _index = 0;
    });
  }

  List<String> _quickActionsForRole(_OpsRole role) {
    return switch (role) {
      _OpsRole.admin => const [
        'إنشاء حجز',
        'إنشاء رحلة',
        'إضافة عميل',
        'إضافة سائق',
      ],
      _OpsRole.customerService => const [
        'إنشاء حجز',
        'إنشاء رحلة',
        'إضافة عميل',
      ],
      _OpsRole.operationsSupervisor => const ['إنشاء رحلة', 'إضافة سائق'],
      _OpsRole.finance => const <String>[],
    };
  }
}

class _OpsNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Set<_OpsRole> roles;
  final Widget Function(_OpsRole role) pageBuilder;

  const _OpsNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.roles,
    required this.pageBuilder,
  });
}

class _OpsSidebar extends StatelessWidget {
  final List<_OpsNavItem> items;
  final _OpsRole role;
  final int selectedIndex;
  final ValueChanged<_OpsRole> onRoleChanged;
  final ValueChanged<int> onSelected;

  const _OpsSidebar({
    required this.items,
    required this.role,
    required this.selectedIndex,
    required this.onRoleChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width:
          AppLayout.maxContentWidthTablet / 2 -
          AppSpacing.large -
          AppSpacing.xSmall,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التشغيل',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'الدور الحالي',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _RoleSelector(role: role, onChanged: onRoleChanged),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.small),
              itemBuilder: (context, index) {
                return _OpsNavButton(
                  item: items[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsMobileDrawer extends StatelessWidget {
  final List<_OpsNavItem> items;
  final _OpsRole role;
  final int selectedIndex;
  final ValueChanged<_OpsRole> onRoleChanged;
  final ValueChanged<int> onSelected;

  const _OpsMobileDrawer({
    required this.items,
    required this.role,
    required this.selectedIndex,
    required this.onRoleChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'لوحة التشغيل',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.medium),
              _RoleSelector(role: role, onChanged: onRoleChanged),
              const SizedBox(height: AppSpacing.xLarge),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.small),
                  itemBuilder: (context, index) {
                    return _OpsNavButton(
                      item: items[index],
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpsNavButton extends StatelessWidget {
  final _OpsNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _OpsNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.82)
          : scheme.surfaceContainerHighest.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: AppTokens.avatarSmall,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final _OpsRole role;
  final ValueChanged<_OpsRole> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_OpsRole>(
      initialValue: role,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.manage_accounts_rounded),
      ),
      items: [
        for (final item in _OpsRole.values)
          DropdownMenuItem(value: item, child: Text(item.label)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _OperationsLandingPage extends StatelessWidget {
  final String title;
  final String nextStep;
  final List<String> tasks;

  const _OperationsLandingPage({
    required this.title,
    required this.nextStep,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.displaySmall),
              const SizedBox(height: AppSpacing.medium),
              Text(
                nextStep,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xLarge),
        AppCard(
          title: 'المهام المتاحة',
          child: Column(
            children: [
              for (final task in tasks) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: Text(task, style: textTheme.bodyLarge)),
                  ],
                ),
                if (task != tasks.last)
                  const SizedBox(height: AppSpacing.medium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const _SettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإعدادات', style: textTheme.displaySmall),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'اضبط تجربة العمل اليومية بدون تغيير نظام التصميم.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xLarge),
        _SettingsSection(
          title: 'المظهر',
          icon: Icons.palette_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('وضع الواجهة', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.medium),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('فاتح'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('داكن'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('تلقائي'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  onThemeModeChanged(selection.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        const _SettingsSection(
          title: 'اللغة',
          icon: Icons.translate_outlined,
          child: _SettingsInfoRow(
            title: 'العربية',
            subtitle: 'واجهة لوحة التشغيل تعمل بالعربية فقط.',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        const _SettingsSection(
          title: 'الإشعارات',
          icon: Icons.notifications_outlined,
          child: Column(
            children: [
              _SettingsInfoRow(
                title: 'تنبيهات التشغيل',
                subtitle:
                    'الرحلات المتأخرة والشكاوى العاجلة والمدفوعات المعلقة.',
                icon: Icons.campaign_outlined,
              ),
              SizedBox(height: AppSpacing.medium),
              _SettingsInfoRow(
                title: 'ملخص نهاية اليوم',
                subtitle: 'تجميع يومي لأهم مهام الفريق.',
                icon: Icons.summarize_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        const _SettingsSection(
          title: 'الأمان',
          icon: Icons.security_outlined,
          child: Column(
            children: [
              _SettingsInfoRow(
                title: 'الصلاحيات حسب الدور',
                subtitle: 'القوائم والأدوات تظهر حسب دور الموظف الحالي.',
                icon: Icons.admin_panel_settings_outlined,
              ),
              SizedBox(height: AppSpacing.medium),
              _SettingsInfoRow(
                title: 'جلسات العمل',
                subtitle: 'مراجعة الأجهزة والجلسات النشطة من إدارة النظام.',
                icon: Icons.devices_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        const _SettingsSection(
          title: 'الحساب',
          icon: Icons.account_circle_outlined,
          child: _SettingsInfoRow(
            title: 'بيانات الموظف',
            subtitle: 'الاسم، الدور، وبيانات التواصل الداخلية.',
            icon: Icons.badge_outlined,
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.medium),
              Text(title, style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          child,
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SettingsInfoRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

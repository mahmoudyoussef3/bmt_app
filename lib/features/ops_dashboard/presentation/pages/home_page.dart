import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../cubit/kpi_cubit.dart';
import '../widgets/app_card.dart';
import 'booking_management_page.dart';
import 'customer_management_page.dart';
import 'trip_operations_page.dart';

class OpsHomePage extends StatefulWidget {
  final String roleLabel;
  final List<String> availableQuickActions;

  const OpsHomePage({
    required this.roleLabel,
    required this.availableQuickActions,
    super.key,
  });

  @override
  State<OpsHomePage> createState() => _OpsHomePageState();
}

class _OpsHomePageState extends State<OpsHomePage> {
  static const _overview = [
    _OverviewItem(
      label: 'الرحلات اليوم',
      value: '٢٤',
      icon: Icons.route_rounded,
    ),
    _OverviewItem(
      label: 'الحجوزات الجديدة',
      value: '١٥٦',
      icon: Icons.event_seat_rounded,
    ),
    _OverviewItem(
      label: 'الشكاوى المفتوحة',
      value: '٣',
      icon: Icons.support_agent_rounded,
    ),
    _OverviewItem(
      label: 'المدفوعات المعلقة',
      value: '٥',
      icon: Icons.payments_rounded,
    ),
  ];

  static const _alerts = [
    _AlertItem(
      title: 'الرحلات المتأخرة',
      detail: 'رحلة واحدة تحتاج متابعة قبل التواصل مع العملاء.',
      icon: Icons.schedule_rounded,
    ),
    _AlertItem(
      title: 'الشكاوى العاجلة',
      detail: '٣ شكاوى مفتوحة بانتظار إجراء من الفريق.',
      icon: Icons.priority_high_rounded,
    ),
    _AlertItem(
      title: 'المدفوعات المعلقة',
      detail: '٥ تحويلات تحتاج مراجعة وتأكيد اليوم.',
      icon: Icons.receipt_long_rounded,
    ),
  ];

  static const _upcomingTrips = [
    _TripItem(
      route: 'بنها ← القرية الذكية',
      time: '٠٨:٣٠ ص',
      driver: 'محمد أحمد',
      seats: '١٠ / ١٢',
    ),
    _TripItem(
      route: 'بنها ← مدينة نصر',
      time: '٠٨:٤٥ ص',
      driver: 'كريم حسن',
      seats: '١٢ / ١٢',
    ),
    _TripItem(
      route: 'بنها ← المهندسين',
      time: '٠٩:٠٠ ص',
      driver: 'مصطفى علي',
      seats: '٨ / ١٢',
    ),
  ];

  @override
  void initState() {
    super.initState();
    context.read<KpiCubit>().loadKpis();
  }

  void _showActionToast(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(label),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAction(String label) {
    switch (label) {
      case 'إنشاء حجز':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookingManagementPage(),
          ),
        );
        return;
      case 'إنشاء رحلة':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TripOperationsPage()),
        );
        return;
      case 'إضافة عميل':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerManagementPage(),
          ),
        );
        return;
      case 'إضافة سائق':
        _showActionToast('فتح نموذج إضافة سائق');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          return ListView(
            children: [
              _DashboardHeader(roleLabel: widget.roleLabel),
              const SizedBox(height: AppSpacing.xLarge),
              _DailyOverview(items: _overview),
              const SizedBox(height: AppSpacing.xLarge),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _QuickActions(
                        actions: widget.availableQuickActions,
                        onSelected: _openAction,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xLarge),
                    const Expanded(flex: 3, child: _Alerts(items: _alerts)),
                  ],
                )
              else ...[
                _QuickActions(
                  actions: widget.availableQuickActions,
                  onSelected: _openAction,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                const _Alerts(items: _alerts),
              ],
              const SizedBox(height: AppSpacing.xLarge),
              const _UpcomingTrips(items: _upcomingTrips),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String roleLabel;

  const _DashboardHeader({required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.space_dashboard_rounded, color: scheme.primary),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الرئيسية', style: textTheme.displaySmall),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'أهم ما يحتاجه فريق $roleLabel اليوم.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyOverview extends StatelessWidget {
  final List<_OverviewItem> items;

  const _DailyOverview({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'نظرة اليوم',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: columns == 1 ? 4 : 2.4,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return AppCard(
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(
                            item.value,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final List<String> actions;
  final ValueChanged<String> onSelected;

  const _QuickActions({required this.actions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'المهام اليومية',
      child: AppCard(
        child: Column(
          children: [
            if (actions.isEmpty)
              Text(
                'لا توجد مهام يومية مباشرة لهذا الدور.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            for (final action in actions) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onSelected(action),
                  icon: Icon(_actionIcon(action)),
                  label: Text(action),
                ),
              ),
              if (action != actions.last)
                const SizedBox(height: AppSpacing.medium),
            ],
          ],
        ),
      ),
    );
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'إنشاء حجز' => Icons.add_rounded,
      'إنشاء رحلة' => Icons.add_road_rounded,
      'إضافة عميل' => Icons.person_add_rounded,
      'إضافة سائق' => Icons.badge_rounded,
      _ => Icons.play_arrow_rounded,
    };
  }
}

class _Alerts extends StatelessWidget {
  final List<_AlertItem> items;

  const _Alerts({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Section(
      title: 'ما يحتاج متابعة',
      child: AppCard(
        child: Column(
          children: [
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, color: scheme.error),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          item.detail,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item != items.last) ...[
                const SizedBox(height: AppSpacing.medium),
                const Divider(),
                const SizedBox(height: AppSpacing.medium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _UpcomingTrips extends StatelessWidget {
  final List<_TripItem> items;

  const _UpcomingTrips({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'الرحلات القادمة',
      child: AppCard(
        child: Column(
          children: [
            for (final trip in items) ...[
              _TripRow(trip: trip),
              if (trip != items.last) ...[
                const SizedBox(height: AppSpacing.medium),
                const Divider(),
                const SizedBox(height: AppSpacing.medium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final _TripItem trip;

  const _TripRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.directions_bus_rounded, color: scheme.primary),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip.route, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                '${trip.time} · ${trip.driver} · ${trip.seats}',
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppSpacing.medium),
        child,
      ],
    );
  }
}

class _OverviewItem {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _AlertItem {
  final String title;
  final String detail;
  final IconData icon;

  const _AlertItem({
    required this.title,
    required this.detail,
    required this.icon,
  });
}

class _TripItem {
  final String route;
  final String time;
  final String driver;
  final String seats;

  const _TripItem({
    required this.route,
    required this.time,
    required this.driver,
    required this.seats,
  });
}

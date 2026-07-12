import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/routes/dashboard_routes.dart';
import '../../../../core/widgets/charts/chart_models.dart';
import '../../../../core/widgets/charts/dashboard_bar_chart.dart';
import '../../../../core/widgets/charts/dashboard_donut_chart.dart';
import '../../../../core/widgets/charts/dashboard_ranked_bars.dart';
import '../../../../core/widgets/dashboard_state_views.dart';
import '../../domain/entities/dashboard_home_data.dart';
import '../cubit/dashboard_home_cubit.dart';
import '../cubit/dashboard_home_state.dart';

class DashboardHomeScreen extends StatelessWidget {
  final ValueChanged<String>? onOpenModule;

  const DashboardHomeScreen({super.key, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
      builder: (context, state) {
        return switch (state) {
          DashboardHomeLoading() => const DashboardLoading(
            rows: 5,
            showHeader: true,
          ),
          DashboardHomeError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<DashboardHomeCubit>().load(),
          ),
          DashboardHomeLoaded(:final data) => _DashboardHomeContent(
            data: data,
            onOpenModule: onOpenModule,
          ),
        };
      },
    );
  }
}

class _DashboardHomeContent extends StatelessWidget {
  final DashboardHomeData data;
  final ValueChanged<String>? onOpenModule;

  const _DashboardHomeContent({required this.data, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 720
        ? AppSpacing.medium
        : AppSpacing.large;

    return ListView(
      cacheExtent: 5000,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.large,
        horizontalPadding,
        AppSpacing.xLarge,
      ),
      children: [
        _HomeHero(data: data, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.large),
        _HomeKpiBand(data: data, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.large),
        _ActionNowSection(items: data.actionItems, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.large),
        _PaymentReviewSection(
          items: data.paymentReviews,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.large),
        _HomeInsightsPanel(data: data),
        const SizedBox(height: AppSpacing.large),
        _TodayTripsSection(trips: data.todayTrips, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.large),
        _TwoColumnSection(
          first: _ComplaintsSection(
            items: data.openComplaints,
            onOpenModule: onOpenModule,
          ),
          second: _SubscriptionsSection(
            items: data.subscriptions,
            onOpenModule: onOpenModule,
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        _AlertsSection(items: data.alerts, onOpenModule: onOpenModule),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  final DashboardHomeData data;
  final ValueChanged<String>? onOpenModule;

  const _HomeHero({required this.data, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgentCount = data.actionItems
        .where((item) => item.priority == OperationsPriority.urgent)
        .fold<int>(0, (sum, item) => sum + _parseDashboardCount(item.count));
    final delayedTrips = data.todayTrips.where(_isAttentionTrip).length;
    final occupancy = _averageOccupancy(data.todayTrips);

    return AppCard(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(color: scheme.outlineVariant.withAlpha(120)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 880;
              final summary = _HeroSummaryRail(
                urgentCount: urgentCount,
                delayedTrips: delayedTrips,
                occupancy: occupancy,
              );
              final title = _HeroTitle(data: data, onOpenModule: onOpenModule);

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.large),
                    summary,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: title),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(flex: 2, child: summary),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final DashboardHomeData data;
  final ValueChanged<String>? onOpenModule;

  const _HeroTitle({required this.data, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendingWork =
        data.paymentReviews.length +
        data.openComplaints.length +
        data.subscriptions.length +
        data.alerts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(
              label: pendingWork == 0 ? 'مستقر' : '$pendingWork متابعة نشطة',
            ),
            StatusChip(label: '${data.todayTrips.length} رحلة اليوم'),
            if (data.paymentReviews.isEmpty)
              const StatusChip(label: 'لا توجد مدفوعات قيد المراجعة'),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'مركز تشغيل BMT',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'لوحة مراقبة حية تجمع الرحلات، المدفوعات، التنبيهات، وخدمة العملاء في مساحة واحدة قابلة للتصرف السريع.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            FilledButton.icon(
              onPressed: () => onOpenModule?.call(DashboardRoutes.liveTrips),
              icon: const Icon(Icons.radar_outlined),
              label: const Text('المراقبة الحية'),
            ),
            OutlinedButton.icon(
              onPressed: () => onOpenModule?.call(DashboardRoutes.trips),
              icon: const Icon(Icons.route_outlined),
              label: const Text('إدارة الرحلات'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  onOpenModule?.call(DashboardRoutes.paymentVerification),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('مراجعة الدفع'),
            ),
          ],
        ),
        if (data.actionItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.large),
          _HeroActionStrip(items: data.actionItems, onOpenModule: onOpenModule),
        ],
      ],
    );
  }
}

class _HeroActionStrip extends StatelessWidget {
  final List<OperationsActionItem> items;
  final ValueChanged<String>? onOpenModule;

  const _HeroActionStrip({required this.items, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: items.take(3).map((item) {
        final color = _priorityColor(context, item.priority);
        return ActionChip(
          avatar: Icon(_moduleIcon(item.targetModule), color: color, size: 18),
          label: Text(item.title, overflow: TextOverflow.ellipsis),
          side: BorderSide(color: color.withAlpha(90)),
          backgroundColor: color.withAlpha(18),
          onPressed: () => onOpenModule?.call(item.targetModule),
        );
      }).toList(),
    );
  }
}

class _HeroSummaryRail extends StatelessWidget {
  final int urgentCount;
  final int delayedTrips;
  final double occupancy;

  const _HeroSummaryRail({
    required this.urgentCount,
    required this.delayedTrips,
    required this.occupancy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(64),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: Column(
        children: [
          _HeroMetricLine(
            icon: Icons.priority_high_rounded,
            label: 'الأولوية العاجلة',
            value: urgentCount.toString(),
            color: urgentCount > 0 ? scheme.error : scheme.primary,
          ),
          const Divider(height: AppSpacing.large),
          _HeroMetricLine(
            icon: Icons.timelapse_outlined,
            label: 'رحلات تحتاج متابعة',
            value: delayedTrips.toString(),
            color: delayedTrips > 0 ? scheme.tertiary : scheme.primary,
          ),
          const Divider(height: AppSpacing.large),
          _HeroMetricLine(
            icon: Icons.event_seat_outlined,
            label: 'متوسط إشغال اليوم',
            value: '${(occupancy * 100).round()}%',
            color: scheme.primary,
          ),
        ],
      ),
    );
  }
}

class _HeroMetricLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroMetricLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withAlpha(24),
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HomeKpiBand extends StatelessWidget {
  final DashboardHomeData data;
  final ValueChanged<String>? onOpenModule;

  const _HomeKpiBand({required this.data, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final availableSeats = data.todayTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.availableSeats.clamp(0, trip.capacity),
    );
    final bookedSeats = data.todayTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.bookedSeats,
    );
    final urgentActions = data.actionItems
        .where((item) => item.priority == OperationsPriority.urgent)
        .fold<int>(0, (sum, item) => sum + _parseDashboardCount(item.count));

    final items = [
      _KpiSpec(
        title: 'رحلات اليوم',
        value: data.todayTrips.length.toString(),
        subtitle:
            '${_activeTripCount(data.todayTrips)} قيد التشغيل أو المتابعة',
        icon: Icons.directions_bus_filled_outlined,
        color: scheme.primary,
        onTap: () => onOpenModule?.call(DashboardRoutes.trips),
      ),
      _KpiSpec(
        title: 'المقاعد المحجوزة',
        value: bookedSeats.toString(),
        subtitle: '$availableSeats مقعد متاح الآن',
        icon: Icons.event_seat_outlined,
        color: const Color(0xFF0F766E),
        onTap: () => onOpenModule?.call(DashboardRoutes.liveTrips),
      ),
      _KpiSpec(
        title: 'مدفوعات قيد المراجعة',
        value: data.paymentReviews.length.toString(),
        subtitle: 'إيصالات تحتاج قرار',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFB45309),
        onTap: () => onOpenModule?.call(DashboardRoutes.paymentVerification),
      ),
      _KpiSpec(
        title: 'إجراءات عاجلة',
        value: urgentActions.toString(),
        subtitle: '${data.alerts.length} تنبيه تشغيلي',
        icon: Icons.notifications_active_outlined,
        color: urgentActions > 0 ? scheme.error : scheme.primary,
        onTap: () => onOpenModule?.call(DashboardRoutes.liveTrips),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 720
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
            mainAxisExtent: 164,
          ),
          itemBuilder: (context, index) => _KpiCard(spec: items[index]),
        );
      },
    );
  }
}

class _KpiSpec {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiSpec({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiSpec spec;

  const _KpiCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: spec.onTap,
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: spec.color.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Icon(spec.icon, color: spec.color, size: 21),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
          const Spacer(),
          Text(
            spec.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: spec.color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(spec.title, style: Theme.of(context).textTheme.titleSmall),
          Text(
            spec.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HomeInsightsPanel extends StatelessWidget {
  final DashboardHomeData data;

  const _HomeInsightsPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusData = _tripStatusData(data.todayTrips, scheme);
    final occupancyData = _occupancyBuckets(data.todayTrips, scheme);
    final routeData = _routeDemandData(data.todayTrips, scheme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1120;
        final cards = [
          _ChartCard(
            title: 'حالة رحلات اليوم',
            subtitle: 'توزيع التشغيل حسب الحالة الحالية',
            child: DashboardDonutChart(data: statusData),
          ),
          _ChartCard(
            title: 'الإشغال',
            subtitle: 'تجميع الرحلات حسب نسبة المقاعد المحجوزة',
            child: DashboardBarChart(data: occupancyData),
          ),
          _ChartCard(
            title: 'أكثر الخطوط طلباً',
            subtitle: 'حسب المقاعد المحجوزة في رحلات اليوم',
            child: DashboardRankedBars(data: routeData),
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last)
                  const SizedBox(height: AppSpacing.medium),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: cards[1]),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}

class _ActionNowSection extends StatelessWidget {
  final List<OperationsActionItem> items;
  final ValueChanged<String>? onOpenModule;

  const _ActionNowSection({required this.items, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'إجراءات تحتاج تدخل الآن',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (items.isEmpty) {
            return const AppCard(
              padding: EdgeInsets.all(AppSpacing.medium),
              child: _CompactEmptyState(
                title: 'لا توجد إجراءات عاجلة الآن',
                subtitle: 'كل قوائم التشغيل المتصلة بالتطبيقات مستقرة حالياً.',
              ),
            );
          }

          final columns = constraints.maxWidth >= 1180
              ? 4
              : constraints.maxWidth >= 760
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
              mainAxisExtent: 178,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ActionCard(
                item: item,
                onTap: () => onOpenModule?.call(item.targetModule),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final OperationsActionItem item;
  final VoidCallback? onTap;

  const _ActionCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priorityColor = _priorityColor(context, item.priority);
    final icon = _moduleIcon(item.targetModule);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Icon(icon, color: priorityColor),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      item.count,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Text(
                _priorityLabel(item.priority),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: priorityColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayTripsSection extends StatelessWidget {
  final List<TodayTripSummary> trips;
  final ValueChanged<String>? onOpenModule;

  const _TodayTripsSection({required this.trips, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'رحلات اليوم',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (trips.isEmpty) {
            return const AppCard(
              padding: EdgeInsets.all(AppSpacing.medium),
              child: EmptyState(
                title: 'لا توجد رحلات مجدولة اليوم',
                subtitle: 'ستظهر الرحلات فور إنشائها في جدول التشغيل.',
              ),
            );
          }

          final columns = constraints.maxWidth >= 1060 ? 2 : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              mainAxisExtent: 214,
            ),
            itemBuilder: (context, index) => _TripCard(
              trip: trips[index],
              onTap: () => onOpenModule?.call(_tripTargetRoute(trips[index])),
            ),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TodayTripSummary trip;
  final VoidCallback? onTap;

  const _TripCard({required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: trip.status),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            trip.route,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.xSmall,
            children: [
              _InlineFact(icon: Icons.badge_outlined, text: trip.driver),
              _InlineFact(
                icon: Icons.directions_bus_outlined,
                text: trip.vehicle,
              ),
              _InlineFact(
                icon: Icons.schedule_outlined,
                text: trip.departureTime,
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text('المقاعد', style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Text(
                'السعة ${trip.capacity} | المحجوز ${trip.bookedSeats} | المتاح ${trip.availableSeats}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          AppProgressBar(progress: trip.occupancyRate),
        ],
      ),
    );
  }
}

class _PaymentReviewSection extends StatelessWidget {
  final List<PaymentReviewItem> items;
  final ValueChanged<String>? onOpenModule;

  const _PaymentReviewSection({required this.items, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'مراجعة المدفوعات',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: items.isEmpty
            ? const _CompactEmptyState(
                title: 'لا توجد إيصالات تنتظر المراجعة',
                subtitle: 'ستظهر طلبات الدفع الجديدة هنا عند وصولها.',
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final split = constraints.maxWidth >= 860;
                  final list = _PaymentList(
                    items: items,
                    onOpenDetails: () =>
                        onOpenModule?.call(DashboardRoutes.paymentVerification),
                  );
                  final receipt = _ReceiptPreview(item: items.first);
                  if (!split) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        list,
                        const SizedBox(height: AppSpacing.medium),
                        receipt,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: list),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(flex: 2, child: receipt),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<PaymentReviewItem> items;
  final VoidCallback? onOpenDetails;

  const _PaymentList({required this.items, this.onOpenDetails});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.indexed.map((entry) {
        final (index, item) = entry;
        return Column(
          children: [
            if (index > 0) const Divider(height: AppSpacing.large),
            _PaymentRow(item: item, onOpenDetails: onOpenDetails),
          ],
        );
      }).toList(),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentReviewItem item;
  final VoidCallback? onOpenDetails;

  const _PaymentRow({required this.item, this.onOpenDetails});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.customerName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                '${item.tripName} - ${item.method} - ${item.amount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Flexible(
          flex: 0,
          child: FilledButton.tonalIcon(
            onPressed: onOpenDetails,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('مراجعة الدفع'),
          ),
        ),
      ],
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final PaymentReviewItem item;

  const _ReceiptPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(90),
        border: Border.all(color: scheme.outline.withAlpha(120)),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  item.receiptTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: scheme.outline.withAlpha(120)),
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 36,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'صورة الإيصال',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            item.receiptMeta,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ComplaintsSection extends StatelessWidget {
  final List<ComplaintTicket> items;
  final ValueChanged<String>? onOpenModule;

  const _ComplaintsSection({required this.items, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'الشكاوى المفتوحة',
      emptyTitle: 'لا توجد شكاوى مفتوحة',
      children: items
          .map(
            (item) => _ComplaintCard(
              item: item,
              onOpen: () => onOpenModule?.call(DashboardRoutes.tickets),
            ),
          )
          .toList(),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintTicket item;
  final VoidCallback? onOpen;

  const _ComplaintCard({required this.item, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: _complaintColor(context, item.status),
            width: 4,
          ),
        ),
        color: scheme.surfaceContainerHighest.withAlpha(56),
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.customerName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              StatusChip(label: item.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '${item.type} - ${item.tripName}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            '${item.lastUpdate} - المسؤول ${item.owner}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.xSmall,
            runSpacing: AppSpacing.xSmall,
            children: [
              FilledButton.tonalIcon(
                onPressed: onOpen,
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('فتح التذكرة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  final List<SubscriptionReviewItem> items;
  final ValueChanged<String>? onOpenModule;

  const _SubscriptionsSection({required this.items, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'الاشتراكات',
      emptyTitle: 'لا توجد اشتراكات تحتاج متابعة',
      children: items
          .map(
            (item) => _SubscriptionRow(
              item: item,
              onOpen: () => onOpenModule?.call(DashboardRoutes.subscriptions),
            ),
          )
          .toList(),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final SubscriptionReviewItem item;
  final VoidCallback? onOpen;

  const _SubscriptionRow({required this.item, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(56),
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.customerName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              StatusChip(label: item.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '${item.packageName} - ${item.route}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'من ${item.startDate} إلى ${item.endDate} - متبقي ${item.remainingTrips} رحلة',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.xSmall,
            runSpacing: AppSpacing.xSmall,
            children: [
              FilledButton.tonalIcon(
                onPressed: onOpen,
                icon: const Icon(Icons.card_membership_outlined),
                label: const Text('إدارة الاشتراك'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final List<OperationsAlert> items;
  final ValueChanged<String>? onOpenModule;

  const _AlertsSection({required this.items, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'تنبيهات التشغيل',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: items.isEmpty
            ? const EmptyState(
                title: 'لا توجد تنبيهات تشغيل',
                subtitle:
                    'أي تأخير أو تعارض أو مستند منتهي سيظهر هنا فور رصده.',
              )
            : Column(
                children: items.indexed.map((entry) {
                  final (index, item) = entry;
                  return Column(
                    children: [
                      if (index > 0) const Divider(height: AppSpacing.large),
                      _AlertRow(
                        item: item,
                        onTap: () => onOpenModule?.call(item.targetModule),
                      ),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final OperationsAlert item;
  final VoidCallback? onTap;

  const _AlertRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _priorityColor(context, item.priority);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: color),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    item.details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _TwoColumnSection extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _TwoColumnSection({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.large),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.large),
            Expanded(child: second),
          ],
        );
      },
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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.medium),
        child,
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
    this.emptyTitle = 'لا توجد عناصر للعرض',
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: children.isEmpty
            ? _CompactEmptyState(title: emptyTitle)
            : Column(
                children: children.indexed.map((entry) {
                  final (index, child) = entry;
                  return Column(
                    children: [
                      if (index > 0) const SizedBox(height: AppSpacing.small),
                      child,
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _InlineFact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineFact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xSmall),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _CompactEmptyState({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(44),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _parseDashboardCount(String value) {
  const arabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };
  final normalized = value.characters.map((char) {
    return arabicDigits[char] ?? char;
  }).join();
  final digits = RegExp(r'\d+').firstMatch(normalized)?.group(0);
  return int.tryParse(digits ?? '') ?? 0;
}

double _averageOccupancy(List<TodayTripSummary> trips) {
  if (trips.isEmpty) return 0;
  final totalCapacity = trips.fold<int>(0, (sum, trip) => sum + trip.capacity);
  if (totalCapacity <= 0) return 0;
  final totalBooked = trips.fold<int>(0, (sum, trip) => sum + trip.bookedSeats);
  return (totalBooked / totalCapacity).clamp(0, 1).toDouble();
}

int _activeTripCount(List<TodayTripSummary> trips) {
  return trips.where((trip) {
    final status = trip.status.trim();
    return status.contains('متأخر') ||
        status.contains('جاري') ||
        status.contains('بدأ') ||
        status.contains('قيد') ||
        status.contains('مفتوح');
  }).length;
}

bool _isAttentionTrip(TodayTripSummary trip) {
  final status = trip.status.trim();
  return status.contains('متأخر') ||
      status.contains('تأخير') ||
      status.contains('ملغي') ||
      status.contains('مشكلة') ||
      trip.occupancyRate >= 0.9 ||
      trip.availableSeats <= 2;
}

List<ChartDatum> _tripStatusData(
  List<TodayTripSummary> trips,
  ColorScheme scheme,
) {
  final counts = <String, int>{};
  for (final trip in trips) {
    final status = trip.status.trim().isEmpty ? 'غير محدد' : trip.status.trim();
    counts[status] = (counts[status] ?? 0) + 1;
  }
  final palette = [
    scheme.primary,
    scheme.tertiary,
    scheme.error,
    const Color(0xFF0F766E),
    const Color(0xFFB45309),
  ];
  var index = 0;
  return counts.entries.map((entry) {
    final datum = ChartDatum(
      label: entry.key,
      value: entry.value.toDouble(),
      color: palette[index % palette.length],
    );
    index++;
    return datum;
  }).toList();
}

List<ChartDatum> _occupancyBuckets(
  List<TodayTripSummary> trips,
  ColorScheme scheme,
) {
  var low = 0;
  var medium = 0;
  var high = 0;
  var full = 0;

  for (final trip in trips) {
    final rate = trip.occupancyRate;
    if (rate >= 0.95) {
      full++;
    } else if (rate >= 0.7) {
      high++;
    } else if (rate >= 0.35) {
      medium++;
    } else {
      low++;
    }
  }

  return [
    ChartDatum(label: 'منخفض', value: low.toDouble(), color: scheme.secondary),
    ChartDatum(label: 'متوسط', value: medium.toDouble(), color: scheme.primary),
    ChartDatum(label: 'مرتفع', value: high.toDouble(), color: scheme.tertiary),
    ChartDatum(label: 'ممتلئ', value: full.toDouble(), color: scheme.error),
  ];
}

List<ChartDatum> _routeDemandData(
  List<TodayTripSummary> trips,
  ColorScheme scheme,
) {
  final totals = <String, int>{};
  for (final trip in trips) {
    totals[trip.route] = (totals[trip.route] ?? 0) + trip.bookedSeats;
  }

  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return entries.take(5).map((entry) {
    return ChartDatum(
      label: entry.key,
      value: entry.value.toDouble(),
      color: scheme.primary,
    );
  }).toList();
}

Color _priorityColor(BuildContext context, OperationsPriority priority) {
  final scheme = Theme.of(context).colorScheme;
  return switch (priority) {
    OperationsPriority.urgent => scheme.error,
    OperationsPriority.high => scheme.tertiary,
    OperationsPriority.normal => scheme.primary,
  };
}

String _priorityLabel(OperationsPriority priority) {
  return switch (priority) {
    OperationsPriority.urgent => 'عاجل',
    OperationsPriority.high => 'أولوية عالية',
    OperationsPriority.normal => 'متابعة',
  };
}

IconData _moduleIcon(String route) {
  return switch (route) {
    DashboardRoutes.paymentVerification => Icons.fact_check_outlined,
    DashboardRoutes.liveTrips => Icons.near_me_outlined,
    DashboardRoutes.tickets => Icons.support_agent_outlined,
    DashboardRoutes.subscriptions => Icons.workspace_premium_outlined,
    DashboardRoutes.trips => Icons.route_outlined,
    DashboardRoutes.vehicles => Icons.directions_bus_outlined,
    DashboardRoutes.drivers => Icons.badge_outlined,
    _ => Icons.open_in_new_rounded,
  };
}

String _tripTargetRoute(TodayTripSummary trip) {
  if (trip.status == 'متأخرة' ||
      trip.status == 'في الطريق' ||
      trip.status == 'وصلت أول نقطة') {
    return DashboardRoutes.liveTrips;
  }

  return DashboardRoutes.trips;
}

Color _complaintColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    'مصعدة' => scheme.error,
    'قيد المعالجة' => scheme.tertiary,
    _ => scheme.primary,
  };
}

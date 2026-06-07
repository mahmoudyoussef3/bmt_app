import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/metric_tile.dart';

import '../../domain/entities/dashboard_home_data.dart';
import '../cubit/dashboard_home_cubit.dart';
import '../cubit/dashboard_home_state.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
      builder: (context, state) {
        return switch (state) {
          DashboardHomeLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          DashboardHomeError(:final message) => Center(child: Text(message)),
          DashboardHomeLoaded(:final data) => _DashboardHomeContent(data: data),
        };
      },
    );
  }
}

class _DashboardHomeContent extends StatelessWidget {
  final DashboardHomeData data;

  const _DashboardHomeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _PageTitle(
          title: 'الرئيسية',
          subtitle: 'مختصر سريع لليوم وما يحتاج تدخل من فريق التشغيل.',
        ),
        const SizedBox(height: AppSpacing.large),
        _MetricGrid(metrics: data.metrics.take(4).toList()),
        const SizedBox(height: AppSpacing.large),
        _QueueSection(
          title: 'يتطلب إجراء',
          items: [
            const DashboardQueueItem(
              title: 'مدفوعات معلقة',
              subtitle: '٥ عمليات تحتاج قبول أو رفض',
              status: 'مراجعة',
            ),
            ...data.tripsNeedingAction,
            ...data.openTickets.take(1),
            const DashboardQueueItem(
              title: 'طلبات اشتراك جديدة',
              subtitle: '٦ طلبات تحتاج مراجعة الباقة',
              status: 'جديد',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        _QueueSection(title: 'آخر العمليات', items: data.recentBookings),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<DashboardMetric> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return MetricTile(
              label: metric.label,
              value: metric.value,
              trend: metric.note,
            );
          },
        );
      },
    );
  }
}

class _QueueSection extends StatelessWidget {
  final String title;
  final List<DashboardQueueItem> items;

  const _QueueSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          ...items.indexed.expand((entry) {
            final (index, item) = entry;
            return [
              if (index > 0) const Divider(height: AppSpacing.medium),
              _QueueRow(item: item),
            ];
          }),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final DashboardQueueItem item;

  const _QueueRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          item.status,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
      ],
    );
  }
}

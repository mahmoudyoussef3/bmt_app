import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/routes/dashboard_routes.dart';
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
    return ListView(
      cacheExtent: 1800,
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        const _PageTitle(),
        const SizedBox(height: AppSpacing.large),
        _ActionNowSection(items: data.actionItems, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.large),
        _TodayTripsSection(trips: data.todayTrips, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.large),
        _PaymentReviewSection(
          items: data.paymentReviews,
          onOpenModule: onOpenModule,
        ),
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

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مركز التشغيل', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'كل ما يحتاج تدخل فعلي من خدمة العملاء والتشغيل اليوم.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
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
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
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
                title: 'لا توجد مدفوعات قيد المراجعة',
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
        border: Border(
          right: BorderSide(
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
            Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
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

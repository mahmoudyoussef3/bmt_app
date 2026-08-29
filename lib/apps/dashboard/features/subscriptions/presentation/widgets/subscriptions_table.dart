import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../models/subscription_sort.dart';
import 'subscription_details_sheet.dart';
import 'subscription_formatting.dart';

/// How many subscribers one page holds — in the table and in the card grid it
/// falls back to, so resizing the console never changes what page you are on.
const int subscriptionsPageSize = 12;

/// The office-wide subscriber list, as a sortable, paginated table — the same
/// [OpsDataTable] shape every other EWT module (Bookings, Tickets, Fleet) uses.
///
/// Only for the no-trip-selected view: a trip in focus carries per-subscriber
/// actions (check-in, ride ledger) that a table row cannot host, so that mode
/// keeps [SubscriptionCard]'s grid instead.
///
/// The page index lives in the board above rather than here: the card layout
/// pages the same list, and two widgets each remembering their own page is how
/// a narrowing window silently moves the operator to a different set of rows.
class SubscriptionsTable extends StatelessWidget {
  const SubscriptionsTable({
    super.key,
    required this.state,
    required this.pageIndex,
    required this.onPageChanged,
  });

  final SubscriptionsLoaded state;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  static const _sortColumns = <int, SubscriptionSortField>{
    0: SubscriptionSortField.name,
    3: SubscriptionSortField.price,
  };

  int? get _sortColumnIndex {
    for (final entry in _sortColumns.entries) {
      if (entry.value == state.sortField) return entry.key;
    }
    return null;
  }

  static const _columns = <OpsColumn>[
    OpsColumn('المشترك', flex: 4, minWidth: 170, sortable: true),
    OpsColumn('الباقة', flex: 3, minWidth: 130),
    OpsColumn('المسار', flex: 3, minWidth: 130),
    OpsColumn('القيمة', flex: 2, minWidth: 100, numeric: true, sortable: true),
    OpsColumn('الحالة', flex: 2, minWidth: 120),
    OpsColumn('', flex: 2, minWidth: 84),
  ];

  @override
  Widget build(BuildContext context) {
    final subscriptions = state.visibleSubscriptions;
    final start = (pageIndex * subscriptionsPageSize).clamp(
      0,
      subscriptions.length,
    );
    final end = (start + subscriptionsPageSize).clamp(0, subscriptions.length);
    final pageItems = subscriptions.sublist(start, end);

    return OpsDataTable(
      columns: _columns,
      rows: [for (final s in pageItems) _row(context, s)],
      onRowTap: [
        for (final s in pageItems) () => openSubscriptionDetails(context, s.id),
      ],
      total: subscriptions.length,
      totalLabel: 'الإجمالي ${arabicNumber(subscriptions.length)} اشتراك',
      currentPage: pageIndex,
      pageSize: subscriptionsPageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: _sortColumnIndex,
      sortDirection: state.sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: (index) {
        final field = _sortColumns[index];
        if (field == null) return;
        context.read<SubscriptionsCubit>().sortBy(field);
        onPageChanged(0);
      },
    );
  }

  List<Widget> _row(BuildContext context, UserSubscription subscription) {
    return [
      _SubscriberCell(subscription: subscription),
      _PackageCell(subscription: subscription),
      Text(
        subscription.routeLabel.isEmpty ? '—' : subscription.routeLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      _ValueCell(subscription: subscription),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _StatusCell(subscription: subscription),
      ),
      _RowActions(subscription: subscription),
    ];
  }
}

class _SubscriberCell extends StatelessWidget {
  const _SubscriberCell({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = subscriptionStatusColor(context, subscription.status);
    final initial = subscription.userName.trim().isEmpty
        ? '؟'
        : subscription.userName.trim().characters.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(28),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(color: statusColor.withAlpha(60)),
          ),
          child: Text(
            initial,
            style: text.labelLarge?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subscription.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'عميل منذ ${subscription.createdAt.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackageCell extends StatelessWidget {
  const _PackageCell({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final primary = subscription.packageName.isNotEmpty
        ? subscription.packageName
        : subscription.type.label;
    final secondary = primary == subscription.type.label
        ? null
        : subscription.type.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final outstanding = subscription.outstandingAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subscriptionMoney(subscription.price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          outstanding > 0
              ? 'متبقٍ ${subscriptionMoney(outstanding)}'
              : 'مدفوع بالكامل',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(
            color: outstanding > 0
                ? context.status(AppStatusTone.error).ink
                : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Near-expiry gets its own countdown badge instead of a plain "نشط" — that is
/// the row an operator is actually scanning the status column for.
class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    if (subscription.isExpiringSoon) {
      final tone = context.status(AppStatusTone.warning);
      return DashboardStatusChip(
        label: 'ينتهي بعد ${arabicNumber(subscription.remainingDays)} أيام',
        color: tone.tint,
        textColor: tone.ink,
      );
    }
    return SubscriptionStatusChip(status: subscription.status);
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 20),
          tooltip: 'عرض التفاصيل',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: () => openSubscriptionDetails(context, subscription.id),
        ),
        PopupMenuButton<void>(
          tooltip: 'إجراءات',
          icon: const Icon(Icons.more_horiz_rounded, size: 20),
          padding: EdgeInsets.zero,
          itemBuilder: (context) => [
            if (subscription.status == SubscriptionStatus.pendingPayment)
              PopupMenuItem(
                onTap: () => cubit.confirmPayment(subscription.id),
                child: const Text('تأكيد استلام الدفع'),
              ),
            if (subscription.status != SubscriptionStatus.cancelled)
              PopupMenuItem(
                onTap: () => cubit.renew(subscription.id),
                child: const Text('تجديد الاشتراك'),
              ),
            if (subscription.status != SubscriptionStatus.cancelled)
              PopupMenuItem(
                onTap: () => cubit.cancel(subscription.id),
                child: const Text('إلغاء الاشتراك'),
              ),
          ],
        ),
      ],
    );
  }
}

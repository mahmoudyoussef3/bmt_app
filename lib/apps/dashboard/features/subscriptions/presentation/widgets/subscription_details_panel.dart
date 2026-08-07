import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import 'subscription_formatting.dart';
import 'subscription_rides_widget.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Everything known about one subscriber, plus every operation the office can
/// run on them. Lives beside the list on desktop (MasterDetailLayout), and
/// replaces it on narrow screens.
class SubscriptionDetailsPanel extends StatelessWidget {
  const SubscriptionDetailsPanel({
    super.key,
    required this.subscription,
    required this.state,
    required this.onClose,
  });

  final UserSubscription subscription;
  final SubscriptionsLoaded state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _Header(subscription: subscription, onClose: onClose),
        const SizedBox(height: AppSpacing.medium),
        _MoneyPanel(subscription: subscription),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.subscriptionDetailInfo,
          icon: Icons.badge_outlined,
          title: 'بيانات الاشتراك',
          subtitle: 'الباقة وخط السير ومدة السريان',
          child: _Facts(
            items: [
              _Fact('العميل', subscription.userName),
              _Fact(
                'الهاتف',
                arabicDigits(
                  subscription.userPhone.isEmpty
                      ? 'غير مسجل'
                      : subscription.userPhone,
                ),
              ),
              _Fact('الباقة', subscription.packageName),
              _Fact('نوع المدة', subscription.type.label),
              _Fact(
                'خط السير',
                subscription.routeLabel.isEmpty
                    ? 'غير مرتبط بخط سير'
                    : subscription.routeLabel,
              ),
              _Fact('تاريخ البداية', subscriptionDate(subscription.startDate)),
              _Fact('تاريخ النهاية', subscriptionDate(subscription.endDate)),
              _Fact(
                'الأيام المتبقية',
                '${arabicNumber(subscription.remainingDays)} يوم',
              ),
              _Fact('عدد التجديدات', arabicNumber(subscription.renewalsCount)),
              _Fact('الحالة', subscription.status.label),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.subscriptionDetailRides,
          icon: Icons.confirmation_number_outlined,
          title: 'رصيد الرحلات',
          subtitle: 'ما استُهلك من الباقة وما تبقى',
          child: SubscriptionRidesSection(subscription: subscription),
        ),
        const SizedBox(height: AppSpacing.medium),
        _RideHistoryPanel(subscription: subscription, state: state),
        if (subscription.originTripId.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          _OriginPanel(subscription: subscription, state: state),
        ],
        const SizedBox(height: AppSpacing.medium),
        _ActionsPanel(
          subscription: subscription,
          isProcessing: state.isProcessing,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subscription, required this.onClose});

  final UserSubscription subscription;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subscription.userName,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subscription.packageName,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        SubscriptionStatusChip(status: subscription.status),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'إغلاق التفاصيل',
        ),
      ],
    );
  }
}

class _MoneyPanel extends StatelessWidget {
  const _MoneyPanel({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final outstanding = subscription.outstandingAmount;
    return DashboardPanel(
      sectionId: DashboardSectionIds.subscriptionDetailAccount,
      icon: Icons.payments_outlined,
      title: 'الحساب',
      subtitle: outstanding > 0
          ? 'لم يتم تحصيل كامل قيمة الاشتراك'
          : 'تم تحصيل كامل قيمة الاشتراك',
      child: Row(
        children: [
          Expanded(
            child: _Amount(
              label: 'قيمة الاشتراك',
              value: subscriptionMoney(subscription.price),
            ),
          ),
          Expanded(
            child: _Amount(
              label: 'المدفوع',
              value: subscriptionMoney(subscription.paidAmount),
              color: context.status(AppStatusTone.success).ink,
            ),
          ),
          Expanded(
            child: _Amount(
              label: 'المتبقي',
              value: subscriptionMoney(outstanding),
              color: outstanding > 0
                  ? context.status(AppStatusTone.error).ink
                  : context.status(AppStatusTone.neutral).ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Which departures this subscriber's rides were actually spent on — the
/// question the ride ledger exists to answer.
class _RideHistoryPanel extends StatelessWidget {
  const _RideHistoryPanel({required this.subscription, required this.state});

  final UserSubscription subscription;
  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history =
        state.rideUsage
            .where((usage) => usage.subscriptionId == subscription.id)
            .toList()
          ..sort((a, b) => b.usedAt.compareTo(a.usedAt));

    return DashboardPanel(
      sectionId: DashboardSectionIds.subscriptionDetailLedger,
      icon: Icons.history_rounded,
      title: 'سجل الرحلات المستهلكة',
      subtitle: 'كل رحلة خُصمت من هذا الاشتراك',
      trailing: Text(
        arabicNumber(history.length),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      child: history.isEmpty
          ? Text(
              subscription.usedRides > 0
                  // Rides consumed before the ledger existed have no trip
                  // attached; claiming otherwise would be inventing data.
                  ? 'لا يوجد سجل مفصّل — استُهلكت '
                        '${arabicNumber(subscription.usedRides)} رحلة قبل تفعيل '
                        'سجل الرحلات.'
                  : 'لم تُستهلك أي رحلة من هذا الاشتراك بعد.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              children: [
                for (final usage in history)
                  _RideHistoryRow(usage: usage, trip: _tripFor(usage.tripId)),
              ],
            ),
    );
  }

  SubscriptionTrip? _tripFor(String? tripId) {
    if (tripId == null) return null;
    for (final trip in state.trips) {
      if (trip.id == tripId) return trip;
    }
    return null;
  }
}

class _RideHistoryRow extends StatelessWidget {
  const _RideHistoryRow({required this.usage, required this.trip});

  final SubscriptionRideUsage usage;
  final SubscriptionTrip? trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              trip == null
                  ? 'رحلة غير محددة'
                  : arabicDigits('${trip!.code} · ${trip!.routeName}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            subscriptionDateTime(usage.usedAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Where the subscription came from, when it came from a booking.
class _OriginPanel extends StatelessWidget {
  const _OriginPanel({required this.subscription, required this.state});

  final UserSubscription subscription;
  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    SubscriptionTrip? origin;
    for (final trip in state.trips) {
      if (trip.id == subscription.originTripId) origin = trip;
    }

    return DashboardPanel(
      sectionId: DashboardSectionIds.subscriptionDetailOrigin,
      icon: Icons.route_rounded,
      title: 'مصدر الاشتراك',
      subtitle: 'الرحلة التي اشترى العميل الباقة أثناء حجزها',
      child: _Facts(
        items: [
          _Fact(
            'رحلة الشراء',
            origin == null
                ? 'رحلة محذوفة أو غير متاحة'
                : arabicDigits(origin.label),
          ),
          if (subscription.originBookingId.isNotEmpty)
            _Fact(
              'رقم الحجز',
              arabicDigits(subscription.originBookingId.split('-').first),
            ),
        ],
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({required this.subscription, required this.isProcessing});

  final UserSubscription subscription;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    final awaitingPayment =
        subscription.status == SubscriptionStatus.pendingPayment;
    final cancelled = subscription.status == SubscriptionStatus.cancelled;

    return DashboardPanel(
      sectionId: DashboardSectionIds.subscriptionDetailActions,
      icon: Icons.bolt_rounded,
      title: 'العمليات',
      subtitle: 'إجراءات المكتب على هذا الاشتراك',
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          if (awaitingPayment)
            FilledButton.icon(
              onPressed: isProcessing
                  ? null
                  : () => cubit.confirmPayment(subscription.id),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('تأكيد استلام الدفع'),
            ),
          FilledButton.tonalIcon(
            onPressed: isProcessing
                ? null
                : () => _confirmRenew(context, cubit),
            icon: const Icon(Icons.autorenew_rounded, size: 18),
            label: const Text('تجديد الاشتراك'),
          ),
          OutlinedButton.icon(
            onPressed: cancelled || isProcessing
                ? null
                : () => _confirmCancel(context, cubit),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('إلغاء الاشتراك'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cancelled
                  ? null
                  : context.status(AppStatusTone.error).ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRenew(
    BuildContext context,
    SubscriptionsCubit cubit,
  ) async {
    final ok = await _ask(
      context,
      title: 'تجديد الاشتراك',
      body:
          'سيتم إنشاء اشتراك جديد بنفس الباقة وخط السير يبدأ بعد نهاية الاشتراك '
          'الحالي، بحالة "بانتظار الدفع".',
    );
    if (ok) await cubit.renew(subscription.id);
  }

  Future<void> _confirmCancel(
    BuildContext context,
    SubscriptionsCubit cubit,
  ) async {
    final ok = await _ask(
      context,
      title: 'إلغاء الاشتراك',
      body:
          'سيتوقف هذا الاشتراك ولن يعود المشترك مؤهلاً للركوب على رحلات خط السير.',
      destructive: true,
    );
    if (ok) await cubit.cancel(subscription.id);
  }

  Future<bool> _ask(
    BuildContext context, {
    required String title,
    required String body,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: context.status(AppStatusTone.error).ink,
                  )
                : null,
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _Fact {
  final String label;
  final String value;

  const _Fact(this.label, this.value);
}

class _Facts extends StatelessWidget {
  const _Facts({required this.items});

  final List<_Fact> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.large,
      runSpacing: AppSpacing.medium,
      children: [
        for (final item in items)
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/subscription_trip.dart';
import '../cubit/subscriptions_cubit.dart';
import '../models/trip_subscriber.dart';
import 'subscription_formatting.dart';

/// The header the screen grows when a trip is in focus: which departure, how
/// many subscribers are expected on it, how many are already on board, what
/// they are riding on and what is still owed.
class TripFocusPanel extends StatelessWidget {
  const TripFocusPanel({
    super.key,
    required this.board,
    required this.isProcessing,
  });

  final TripSubscriberBoard board;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trip = board.trip;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(16),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radius),
                topRight: Radius.circular(AppTokens.radius),
              ),
              border: Border(
                bottom: BorderSide(color: scheme.outline.withAlpha(40)),
              ),
            ),
            child: _TripIdentity(trip: trip),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardKpiGrid(
                  children: [
                    DashboardKpiCard(
                      label: 'مشتركون على الرحلة',
                      value: arabicNumber(board.expectedCount),
                      icon: Icons.groups_2_outlined,
                    ),
                    DashboardKpiCard(
                      label: 'تم تسجيل ركوبهم',
                      value: arabicNumber(board.checkedInCount),
                      detail: 'من ${arabicNumber(board.expectedCount)}',
                      icon: Icons.how_to_reg_outlined,
                      color: AppStatusColors.onSuccessContainer,
                    ),
                    DashboardKpiCard(
                      label: 'بانتظار التسجيل',
                      value: arabicNumber(board.pendingCheckInCount),
                      icon: Icons.pending_actions_outlined,
                      color: AppStatusColors.onWarningContainer,
                    ),
                    DashboardKpiCard(
                      label: 'مستحقات غير محصلة',
                      value: subscriptionMoney(board.outstandingAmount),
                      detail: '${arabicNumber(board.unpaidCount)} مشترك',
                      icon: Icons.account_balance_wallet_outlined,
                      color: board.outstandingAmount > 0
                          ? AppStatusColors.onErrorContainer
                          : AppStatusColors.onNeutralContainer,
                    ),
                  ],
                ),
                if (board.subscribers.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.medium),
                  _PackageBreakdown(breakdown: board.packageBreakdown),
                ],
                if (board.pendingCheckInCount > 0) ...[
                  const SizedBox(height: AppSpacing.medium),
                  _CheckInAllAction(board: board, isProcessing: isProcessing),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripIdentity extends StatelessWidget {
  const _TripIdentity({required this.trip});

  final SubscriptionTrip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Icon(
            Icons.directions_bus_filled_rounded,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.code.isEmpty ? 'رحلة' : arabicDigits(trip.code),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                trip.routeName.isEmpty ? 'خط سير غير محدد' : trip.routeName,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          alignment: WrapAlignment.end,
          children: [
            if (trip.date != null)
              _TripFact(
                icon: Icons.calendar_today_rounded,
                value: subscriptionDate(trip.date!),
              ),
            if (trip.departureTime.isNotEmpty)
              _TripFact(
                icon: Icons.schedule_rounded,
                value: arabicDigits(
                  trip.departureTime.split(':').take(2).join(':'),
                ),
              ),
            _TripFact(icon: Icons.flag_outlined, value: _statusLabel),
          ],
        ),
      ],
    );
  }

  String get _statusLabel => switch (trip.status) {
    'scheduled' => 'مجدولة',
    'in_progress' || 'active' => 'جارية',
    'completed' => 'مكتملة',
    'cancelled' => 'ملغاة',
    _ => trip.status.isEmpty ? 'غير محددة' : trip.status,
  };
}

class _TripFact extends StatelessWidget {
  const _TripFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(value, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// "Subscribed for which package" — answered for the whole departure at once.
class _PackageBreakdown extends StatelessWidget {
  const _PackageBreakdown({required this.breakdown});

  final Map<String, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الباقات على هذه الرحلة',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final entry in entries)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outline.withAlpha(70)),
                ),
                child: Text(
                  '${entry.key} · ${arabicNumber(entry.value)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Records a ride for every subscriber on the board who still needs one.
///
/// Each row still goes through the same per-subscription RPC — this only saves
/// the operator from tapping through a full bus one card at a time.
class _CheckInAllAction extends StatelessWidget {
  const _CheckInAllAction({required this.board, required this.isProcessing});

  final TripSubscriberBoard board;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final pending = board.subscribers
        .where((subscriber) => subscriber.canRecordRide)
        .toList();

    return FilledButton.icon(
      onPressed: isProcessing ? null : () => _confirm(context, pending),
      icon: const Icon(Icons.how_to_reg_rounded),
      label: Text('تسجيل ركوب الكل (${arabicNumber(pending.length)})'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    List<TripSubscriber> pending,
  ) async {
    final cubit = context.read<SubscriptionsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل ركوب الكل'),
        content: Text(
          'سيتم خصم رحلة واحدة من رصيد ${arabicNumber(pending.length)} مشترك '
          'على رحلة ${arabicDigits(board.trip.code)}.\n'
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await cubit.markRidesUsedForTrip(
      subscriptionIds: [
        for (final subscriber in pending) subscriber.subscription.id,
      ],
      tripId: board.trip.id,
    );
  }
}

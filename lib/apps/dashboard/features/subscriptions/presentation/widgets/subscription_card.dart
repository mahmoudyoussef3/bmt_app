import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import '../models/trip_subscriber.dart';
import 'subscription_formatting.dart';
import 'subscription_rides_widget.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// One subscriber row.
///
/// [tripSubscriber] is supplied only on a trip board, where the card gains the
/// link chip explaining *why* this person is on this departure and the action
/// to record their ride on it.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.selected,
    required this.onTap,
    this.tripSubscriber,
    this.tripId,
    this.isProcessing = false,
  });

  final UserSubscription subscription;
  final bool selected;
  final VoidCallback onTap;
  final TripSubscriber? tripSubscriber;
  final String? tripId;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = subscriptionStatusColor(context, subscription.status);

    return Stack(
      // Passes the grid's row height straight through to the card, so cards
      // sharing a row end at the same edge instead of floating at their own
      // content heights. Outside a stretching row the constraints are loose and
      // the card still sizes to its content.
      fit: StackFit.passthrough,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: subscription.userName, color: statusColor),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          arabicDigits(
                            subscription.userPhone.isEmpty
                                ? 'لا يوجد رقم'
                                : subscription.userPhone,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  SubscriptionStatusChip(status: subscription.status),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _Tag(
                    icon: Icons.inventory_2_outlined,
                    label: subscription.packageName,
                    emphasised: true,
                  ),
                  if (subscription.routeLabel.isNotEmpty)
                    _Tag(
                      icon: Icons.alt_route_rounded,
                      label: subscription.routeLabel,
                    ),
                  _Tag(
                    icon: Icons.event_available_outlined,
                    label:
                        '${subscriptionDate(subscription.startDate)} — '
                        '${subscriptionDate(subscription.endDate)}',
                  ),
                  if (subscription.status == SubscriptionStatus.active)
                    _Tag(
                      icon: Icons.hourglass_bottom_rounded,
                      label:
                          'متبقٍ ${arabicNumber(subscription.remainingDays)} يوم',
                      tint: subscription.isExpiringSoon
                          ? context.status(AppStatusTone.warning).ink
                          : null,
                    ),
                ],
              ),
              if (tripSubscriber != null) ...[
                const SizedBox(height: AppSpacing.medium),
                _TripLinkRow(subscriber: tripSubscriber!),
              ],
              const SizedBox(height: AppSpacing.medium),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: subscription.totalRides > 0
                        ? SubscriptionRidesBalancePill(
                            subscription: subscription,
                          )
                        : Text(
                            'باقة بالمدة — بدون رصيد رحلات',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  _MoneyBlock(subscription: subscription),
                ],
              ),
              if (tripSubscriber != null && tripId != null) ...[
                const SizedBox(height: AppSpacing.medium),
                _TripCheckInButton(
                  subscriber: tripSubscriber!,
                  tripId: tripId!,
                  isProcessing: isProcessing,
                ),
              ],
            ],
          ),
        ),
        if (selected)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    this.emphasised = false,
    this.tint,
  });

  final IconData icon;
  final String label;
  final bool emphasised;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? (emphasised ? scheme.primary : scheme.onSurface);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasised || tint != null
            ? color.withAlpha(20)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasised || tint != null
              ? color.withAlpha(60)
              : scheme.outline.withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyBlock extends StatelessWidget {
  const _MoneyBlock({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final outstanding = subscription.outstandingAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          subscriptionMoney(subscription.price),
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          outstanding > 0
              ? 'متبقٍ ${subscriptionMoney(outstanding)}'
              : 'مدفوع بالكامل',
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

/// Why this subscriber appears on the trip, and when their ride was recorded.
class _TripLinkRow extends StatelessWidget {
  const _TripLinkRow({required this.subscriber});

  final TripSubscriber subscriber;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final link = subscriber.primaryLink;
    final color = switch (link) {
      TripSubscriberLink.rode => context.status(AppStatusTone.success).ink,
      TripSubscriberLink.booked => scheme.primary,
      TripSubscriberLink.eligible => context.status(AppStatusTone.warning).ink,
    };
    final icon = switch (link) {
      TripSubscriberLink.rode => Icons.how_to_reg_rounded,
      TripSubscriberLink.booked => Icons.confirmation_number_outlined,
      TripSubscriberLink.eligible => Icons.event_seat_outlined,
    };

    final recordedAt = subscriber.rideRecordedAt;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  recordedAt != null
                      ? 'سُجلت في ${subscriptionDateTime(recordedAt)}'
                      : link.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _TripCheckInButton extends StatelessWidget {
  const _TripCheckInButton({
    required this.subscriber,
    required this.tripId,
    required this.isProcessing,
  });

  final TripSubscriber subscriber;
  final String tripId;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    if (subscriber.hasRidden) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: const Text('تم تسجيل الركوب'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
      );
    }

    final subscription = subscriber.subscription;
    final blocked = !subscription.canConsumeRide;

    return Tooltip(
      message: blocked ? _blockReason(subscription) : '',
      child: FilledButton.icon(
        onPressed: blocked || isProcessing ? null : () => _confirm(context),
        icon: const Icon(Icons.how_to_reg_outlined, size: 18),
        label: const Text('تسجيل الركوب على هذه الرحلة'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
      ),
    );
  }

  /// The RPC applies these same conditions; saying which one failed saves the
  /// operator from a rejected action with no explanation.
  static String _blockReason(UserSubscription subscription) {
    if (subscription.status != SubscriptionStatus.active) {
      return 'الاشتراك ${subscription.status.label} — لا يمكن تسجيل ركوب';
    }
    if (subscription.totalRides > 0 && subscription.remainingRides <= 0) {
      return 'رصيد الرحلات منتهٍ';
    }
    return 'تاريخ الرحلة خارج مدة الاشتراك';
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<SubscriptionsCubit>();
    final subscription = subscriber.subscription;
    final remainingAfter = subscription.totalRides > 0
        ? arabicNumber(subscription.remainingRides - 1)
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الركوب'),
        content: Text(
          'تسجيل ركوب ${subscription.userName} على هذه الرحلة'
          '${remainingAfter == null ? '' : '.\nالمتبقي بعد الخصم: $remainingAfter رحلة'}',
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

    await cubit.markRideUsed(subscription.id, tripId: tripId);
  }
}

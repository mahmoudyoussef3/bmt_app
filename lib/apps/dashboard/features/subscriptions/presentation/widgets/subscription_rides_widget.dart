import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/user_subscription.dart';
import '../cubit/subscriptions_cubit.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'subscription_formatting.dart';

/// Compact rides-balance indicator used inside list cards.
class SubscriptionRidesBalancePill extends StatelessWidget {
  final UserSubscription subscription;

  const SubscriptionRidesBalancePill({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final total = subscription.totalRides;
    if (total == 0) return const SizedBox.shrink();

    final used = subscription.usedRides;
    final remaining = subscription.remainingRides;
    final fraction = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final scheme = Theme.of(context).colorScheme;

    final barColor = switch (fraction) {
      > 0.85 => context.status(AppStatusTone.error).ink,
      > 0.60 => context.status(AppStatusTone.warning).ink,
      _ => context.status(AppStatusTone.success).ink,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.confirmation_num_outlined, size: 14),
            const SizedBox(width: 4),
            Text(
              'رصيد الرحلات: $remaining / $total',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

/// Full rides-usage section shown in the subscription details screen.
class SubscriptionRidesSection extends StatelessWidget {
  final UserSubscription subscription;

  const SubscriptionRidesSection({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final total = subscription.totalRides;
    final used = subscription.usedRides;
    final remaining = subscription.remainingRides;
    final fraction = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final scheme = Theme.of(context).colorScheme;

    final barColor = switch (fraction) {
      > 0.85 => context.status(AppStatusTone.error).ink,
      > 0.60 => context.status(AppStatusTone.warning).ink,
      _ => context.status(AppStatusTone.success).ink,
    };

    final canUse =
        subscription.status == SubscriptionStatus.active &&
        (total == 0 || remaining > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'إجمالي الرحلات',
                value: arabicNumber(total),
              ),
            ),
            Expanded(
              child: _Stat(label: 'مستخدمة', value: arabicNumber(used)),
            ),
            Expanded(
              child: _Stat(
                label: 'متبقية',
                value: arabicNumber(remaining),
                highlight: true,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          '${arabicNumber((fraction * 100).round())}٪ مستخدم',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.medium),
        _MarkRideUsedButton(
          subscriptionId: subscription.id,
          canUse: canUse,
          total: total,
          remaining: remaining,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? color : null,
          ),
        ),
      ],
    );
  }
}

class _MarkRideUsedButton extends StatelessWidget {
  final String subscriptionId;
  final bool canUse;
  final int total;
  final int remaining;

  const _MarkRideUsedButton({
    required this.subscriptionId,
    required this.canUse,
    required this.total,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: context.status(AppStatusTone.neutral).tint,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        child: Text(
          'هذا الاشتراك غير مرتبط بباقة برصيد رحلات (اشتراك قديم).',
          style: TextStyle(
            fontSize: 12,
            color: context.status(AppStatusTone.neutral).ink,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: canUse ? () => _confirm(context) : null,
      icon: const Icon(Icons.confirmation_num_outlined),
      label: Text(remaining > 0 ? 'تسجيل رحلة مستخدمة' : 'الرصيد منتهٍ'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        backgroundColor: canUse
            ? context.status(AppStatusTone.success).ink
            : null,
        foregroundColor: canUse ? Colors.white : null,
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل رحلة مستخدمة'),
        content: Text(
          'هل تريد خصم رحلة من رصيد الاشتراك؟\n'
          'المتبقي بعد الخصم: ${arabicNumber(remaining - 1)} رحلة.\n'
          'ملاحظة: هذه الرحلة لن تُربط برحلة محددة في السجل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<SubscriptionsCubit>().markRideUsed(subscriptionId);
    }
  }
}

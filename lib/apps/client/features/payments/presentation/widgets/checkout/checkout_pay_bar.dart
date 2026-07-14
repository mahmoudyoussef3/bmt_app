import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// The pinned bar the rider actually presses.
///
/// The amount lives here rather than only in the fare card, because this is the
/// last thing under their thumb — and a pay button whose number they have to
/// scroll back up to check is how a rider ends up paying an amount they did not
/// mean to. When the payment cannot go through, the reason sits directly above
/// the disabled button instead of waiting to fire as a snackbar on tap.
class CheckoutPayBar extends StatelessWidget {
  const CheckoutPayBar({
    super.key,
    required this.total,
    required this.subtotal,
    required this.label,
    required this.onPay,
    this.blockedReason,
  });

  final int total;
  final int subtotal;
  final String label;
  final VoidCallback? onPay;
  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
    final reason = blockedReason;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
        boxShadow: ClientElevation.lg(context),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reason != null) ...[
              _BlockedReason(reason: reason),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                _TotalBlock(total: total, subtotal: subtotal),
                const SizedBox(width: 16),
                Expanded(
                  child: ClientButton(
                    label: label,
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    onPressed: onPay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your seat is held while you pay.',
              textAlign: TextAlign.center,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalBlock extends StatelessWidget {
  const _TotalBlock({required this.total, required this.subtotal});

  final int total;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total',
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: ClientMotion.base,
          child: Text(
            '$total EGP',
            key: ValueKey(total),
            style: ClientTypography.priceMedium(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
        ),
        if (subtotal > total)
          Text(
            '$subtotal EGP',
            style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class _BlockedReason extends StatelessWidget {
  const _BlockedReason({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final tone = ClientColors.journeyBadgeFor(
      context,
      ClientJourneyStatus.cancelled,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: tone.label),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: tone.fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

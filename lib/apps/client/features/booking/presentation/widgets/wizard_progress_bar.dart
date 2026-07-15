import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class WizardProgressBar extends StatelessWidget {
  const WizardProgressBar({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.booking_stepStops,
      l10n.notifications_categoryTrip,
      l10n.payments_stepSeat,
      l10n.loyalty_categoryPackage,
      l10n.booking_summary,
      l10n.payments_stepPayment,
    ];
    final progress = (step + 1) / labels.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labels[step],
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(color: ClientColors.primaryFor(context)),
                ),
              ),
              Text(
                l10n.booking_stepXOfY(step + 1, labels.length),
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 280),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                color: ClientColors.primaryFor(context),
                backgroundColor: ClientColors.surfaceMutedFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

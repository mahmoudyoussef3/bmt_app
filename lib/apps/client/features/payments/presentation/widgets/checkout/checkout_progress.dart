import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Where the rider is in the booking, drawn as three steps.
///
/// Payment is the step people abandon; showing that the seat is already picked
/// and that a ticket comes right after tells them how much is left to do.
class CheckoutProgress extends StatelessWidget {
  const CheckoutProgress({super.key, this.currentStep = 1});

  /// Zero-based index of the step the rider is on.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = [
      context.l10n.payments_stepSeat,
      context.l10n.payments_stepPayment,
      context.l10n.payments_stepTicket,
    ];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _Step(
            label: steps[i],
            done: i < currentStep,
            active: i == currentStep,
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i < currentStep
                      ? ClientColors.primaryFor(context)
                      : ClientColors.borderFor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, required this.active});

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);
    final reached = done || active;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? primary : Colors.transparent,
            border: Border.all(
              color: reached ? primary : ClientColors.borderStrongFor(context),
              width: 1.6,
            ),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: ClientColors.textInverse,
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: ClientTypography.labelMedium(context).copyWith(
            color: reached
                ? ClientColors.textPrimaryFor(context)
                : ClientColors.textTertiaryFor(context),
          ),
        ),
      ],
    );
  }
}

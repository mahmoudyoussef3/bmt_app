import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/widgets/client_step_progress.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The booking wizard's header.
///
/// Replaces the old single filled rule: a bar can only say "you are 4/6 of the
/// way", while the marker row names and numbers every step, so a rider can see
/// that seat selection is behind them and payment is still two screens off
/// without reading a counter.
///
/// The horizontal padding is narrower than a screen gutter on purpose — six
/// steps have to share the width, and every pixel taken here comes out of the
/// step labels.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: ClientStepProgress(labels: labels, currentIndex: step),
    );
  }
}

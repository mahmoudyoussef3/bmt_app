import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';

/// The one thing the trip's current stage says to do next.
///
/// The stage — not the raw status — decides, because two different gates have
/// to be satisfied before a captain can board passengers:
///
/// 1. **Operations** must publish the trip (`scheduled → open_for_booking`).
///    The backend's `update_trip_status` machine rejects `scheduled →
///    boarding` outright, so a button offered in that state could only throw
///    "حالة الرحلة لا تسمح بهذا الانتقال" at the captain.
/// 2. **The clock** must reach the boarding window. A trip published at dawn
///    for an evening departure is bookable all day; that is not an invitation
///    to start loading it.
///
/// Both waiting states render as a disabled panel that says what is being
/// waited on, and the screen's live watch flips out of them on its own — the
/// captain never has to leave and come back to see the button arm.
class TripExecutionPrimaryAction extends StatelessWidget {
  const TripExecutionPrimaryAction({
    super.key,
    required this.status,
    required this.tripId,
    required this.departureTime,
  });

  final TripExecutionStatus status;
  final String tripId;
  final DateTime departureTime;

  @override
  Widget build(BuildContext context) {
    return CaptainTicker(
      builder: (context, now) {
        final stage = status.stageAt(departureTime: departureTime, now: now);

        return switch (stage) {
          CaptainTripStage.awaitingRelease ||
          CaptainTripStage.awaitingWindow => _WaitingPanel(
            title: CaptainTripStageLabels.action(stage),
            message: CaptainTripStageLabels.status(
              stage: stage,
              departureTime: departureTime,
              now: now,
            ),
            icon: stage == CaptainTripStage.awaitingRelease
                ? Icons.lock_clock_rounded
                : Icons.hourglass_top_rounded,
          ),

          // All three take the shared stage palette rather than a local
          // literal: this button used to be `Colors.orange` for boarding and
          // `CaptainColors.success` for underway, while the same trip was drawn
          // amber and sky by every other screen. The palette's colours are also
          // the ones dark enough to carry a legible label — see
          // `CaptainTripStagePalette.accent`.
          CaptainTripStage.readyToBoard => _ActionButton(
            onPressed: () => context.read<TripExecutionCubit>().board(tripId),
            icon: Icons.people_alt_rounded,
            label: CaptainTripStageLabels.action(stage),
            color: CaptainTripStagePalette.accent(stage),
          ),

          CaptainTripStage.boarding => _ActionButton(
            onPressed: () => context.read<TripExecutionCubit>().start(tripId),
            icon: Icons.play_circle_fill_rounded,
            label: CaptainTripStageLabels.action(stage),
            color: CaptainTripStagePalette.accent(stage),
          ),

          CaptainTripStage.underway => _ActionButton(
            onPressed: () => _confirmAndComplete(context),
            icon: Icons.check_circle_rounded,
            label: CaptainTripStageLabels.action(stage),
            color: CaptainTripStagePalette.accent(stage),
          ),

          // A terminal state, not an action — disabled (not a live button that
          // silently does nothing) so it reads as "this trip is done" rather
          // than as a tappable control.
          CaptainTripStage.finished ||
          CaptainTripStage.cancelled => _TerminalLabel(stage: stage),
        };
      },
    );
  }

  /// Completing a trip is a terminal, irreversible transition — confirm
  /// before firing it so one mis-tap while driving can't end the trip.
  ///
  /// The `mounted` re-check matters: the captain can pop this screen while the
  /// dialog is up, and firing `complete` at a torn-down route would drive the
  /// cubit after it closed.
  Future<void> _confirmAndComplete(BuildContext context) async {
    final confirmed = await CaptainConfirmDialog.show(
      context,
      title: 'إنهاء الرحلة',
      message: 'هل أنت متأكد من إنهاء الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'إنهاء الرحلة',
      confirmColor: CaptainColors.success,
    );
    if (confirmed && context.mounted) {
      context.read<TripExecutionCubit>().complete(tripId);
    }
  }
}

/// A gate the captain cannot open, stated plainly. Deliberately not a greyed
/// button: there is nothing to press, and the reason is the useful part.
///
/// Sized to the same 56 as the live button so the docked bar keeps one height
/// across every stage and the page above it never reflows on a transition.
class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.06),
        borderRadius: CaptainDesignTokens.br16,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: CaptainColors.textSecondaryFor(context)),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                // One line, so the bar keeps the same height as the live
                // button it alternates with — a docked bar that changes height
                // on a stage transition reflows the whole page under the
                // captain's thumb.
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelSmall(context).copyWith(
                    color: CaptainColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _TerminalLabel extends StatelessWidget {
  const _TerminalLabel({required this.stage});

  final CaptainTripStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CaptainColors.offline.withValues(alpha: 0.10),
        borderRadius: CaptainDesignTokens.br16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CaptainTripStagePalette.icon(stage),
            size: 20,
            color: CaptainColors.textSecondaryFor(context),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Text(
            CaptainTripStageLabels.action(stage),
            style: CaptainTypography.titleSmall(context).copyWith(
              fontWeight: FontWeight.w800,
              color: CaptainColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The live control. Full-bleed inside the docked bar, at the height every
/// other primary control in the app uses.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Measured against the fill: boarding is amber, and a white label on it is
    // 2:1. See `CaptainTripStagePalette.onAccent`.
    final foreground = CaptainTripStagePalette.onAccent(color);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: color,
        borderRadius: CaptainDesignTokens.br16,
        child: InkWell(
          onTap: onPressed,
          borderRadius: CaptainDesignTokens.br16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: foreground),
              const SizedBox(width: CaptainDesignTokens.s8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: CaptainTypography.titleMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w900, color: foreground),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

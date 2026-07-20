import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
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

          CaptainTripStage.readyToBoard => _ActionButton(
            onPressed: () => context.read<TripExecutionCubit>().board(tripId),
            icon: Icons.people_alt_rounded,
            label: CaptainTripStageLabels.action(stage),
            color: CaptainColors.primary,
          ),

          CaptainTripStage.boarding => _ActionButton(
            onPressed: () => context.read<TripExecutionCubit>().start(tripId),
            icon: Icons.play_circle_fill_rounded,
            label: CaptainTripStageLabels.action(stage),
            color: Colors.orange,
          ),

          CaptainTripStage.underway => _ActionButton(
            onPressed: () => _confirmAndComplete(context),
            icon: Icons.check_circle_rounded,
            label: CaptainTripStageLabels.action(stage),
            color: CaptainColors.success,
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
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.06),
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(color: CaptainColors.dividerFor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: CaptainColors.textSecondaryFor(context)),
          const SizedBox(width: CaptainDesignTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: CaptainTypography.bodySmall(context).copyWith(
                    color: CaptainColors.textSecondaryFor(context),
                    height: 1.5,
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
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s16),
        shape: const RoundedRectangleBorder(
          borderRadius: CaptainDesignTokens.br16,
        ),
      ),
      child: Text(
        CaptainTripStageLabels.action(stage),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s20,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: CaptainDesignTokens.br24,
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: CaptainTypography.titleMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

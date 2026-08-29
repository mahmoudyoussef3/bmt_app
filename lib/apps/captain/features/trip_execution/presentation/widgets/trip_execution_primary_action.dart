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

double dockedActionHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(56).clamp(56.0, 96.0);

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

          CaptainTripStage.finished ||
          CaptainTripStage.cancelled => _TerminalLabel(stage: stage),
        };
      },
    );
  }

  Future<void> _confirmAndComplete(BuildContext context) async {
    final confirmed = await CaptainConfirmDialog.show(
      context,
      title: 'إنهاء الرحلة',
      message: 'هل أنت متأكد من إنهاء الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'إنهاء الرحلة',
      confirmColor: CaptainColors.primary,
    );
    if (confirmed && context.mounted) {
      context.read<TripExecutionCubit>().complete(tripId);
    }
  }
}

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
      height: dockedActionHeight(context),
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
      height: dockedActionHeight(context),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.offline.withValues(alpha: 0.10),
        borderRadius: CaptainDesignTokens.br16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CaptainTripStagePalette.icon(stage),
            size: 20,
            color: CaptainColors.textSecondaryFor(context),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Flexible(
            child: Text(
              CaptainTripStageLabels.action(stage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.titleSmall(context).copyWith(
                fontWeight: FontWeight.w800,
                color: CaptainColors.textSecondaryFor(context),
              ),
            ),
          ),
        ],
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
    final foreground = CaptainTripStagePalette.onAccent(color);

    return SizedBox(
      width: double.infinity,
      height: dockedActionHeight(context),
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

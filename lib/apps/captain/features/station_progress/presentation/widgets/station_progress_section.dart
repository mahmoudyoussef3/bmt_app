import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../cubit/station_progress_cubit.dart';
import '../cubit/station_progress_state.dart';
import '../formatters/station_labels.dart';
import 'current_station_panel.dart';
import 'station_no_show_sheet.dart';
import 'station_timeline.dart';

/// The station half of the trip screen: the current station, then the route.
///
/// The primary action is deliberately *not* here — it lives docked at the bottom
/// of the screen where a driver's thumb is, and this scrolls above it.
class StationProgressSection extends StatelessWidget {
  const StationProgressSection({
    super.key,
    required this.state,
    required this.now,
  });

  final StationProgressState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const _Placeholder();
    if (!state.hasBoard) return const SizedBox.shrink();

    final board = state.board;
    final focus = board.focusStation;
    final failure = state.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failure != null) ...[
          _FailureNote(message: StationLabels.failure(failure)),
          const SizedBox(height: CaptainDesignTokens.s16),
        ],
        if (focus != null) ...[
          CurrentStationPanel(
            station: focus,
            gate: focus.isCurrent ? board.gateAt(now) : null,
            eta: _etaFor(board, focus),
            now: now,
            isLast: board.stations.last.id == focus.id,
            onReportNoShow: focus.isCurrent && focus.pendingCount > 0
                ? () => showStationNoShowSheet(context, station: focus)
                : null,
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
        ],
        CaptainSectionLabel(
          'مسار الرحلة · ${StationLabels.stations(board.remainingCount)} متبقية',
        ),
        StationTimeline(board: board, now: now),
      ],
    );
  }

  StationEta? _etaFor(StationBoard board, TripStation station) {
    for (final eta in board.etas(now)) {
      if (eta.station.id == station.id) return eta;
    }
    return null;
  }
}

/// A refused transition, shown where the captain was looking when it happened.
///
/// Dismissed by tapping, rather than auto-hiding: "متبقي راكب واحد" is the
/// answer to what they just tried to do, and it should still be there when they
/// look up from the door.
class _FailureNote extends StatelessWidget {
  const _FailureNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<StationProgressCubit>().dismissFailure(),
        borderRadius: CaptainDesignTokens.br16,
        child: Container(
          padding: const EdgeInsets.all(CaptainDesignTokens.s16),
          decoration: BoxDecoration(
            color: CaptainColors.error.withValues(alpha: 0.12),
            borderRadius: CaptainDesignTokens.br16,
            border: Border.all(
              color: CaptainColors.error.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: CaptainColors.error,
                size: 22,
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              Expanded(
                child: Text(
                  message,
                  style: CaptainTypography.bodyMedium(context).copyWith(
                    color: CaptainColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.close_rounded,
                size: 18,
                color: CaptainColors.textSecondaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../formatters/station_labels.dart';

/// The whole route as a spine: what has been passed, where the vehicle is, and
/// what is left with an estimate against each.
///
/// Reference material, not a control — nothing here is tappable. The captain
/// acts through the one primary action at the bottom of the screen; this is
/// where they look to answer "how much of this is left".
class StationTimeline extends StatelessWidget {
  const StationTimeline({super.key, required this.board, required this.now});

  final StationBoard board;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) return const SizedBox.shrink();

    final etas = board.etas(now);

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br20,
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s8,
      ),
      child: Column(
        children: [
          for (final (index, eta) in etas.indexed)
            _StationRow(
              eta: eta,
              isFirst: index == 0,
              isLast: index == etas.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.eta,
    required this.isFirst,
    required this.isLast,
  });

  final StationEta eta;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final station = eta.station;
    final isCurrent = station.isCurrent;
    final done = station.hasDeparted;

    final color = done || isCurrent
        ? CaptainColors.primary
        : CaptainColors.textSecondaryFor(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Spine(
            color: color,
            filled: done || isCurrent,
            isFirst: isFirst,
            isLast: isLast,
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CaptainDesignTokens.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      color: done
                          ? CaptainColors.textSecondaryFor(context)
                          : CaptainColors.textPrimaryFor(context),
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Detail(eta: eta),
                ],
              ),
            ),
          ),
          if (station.expectedBoardings > 0)
            Center(child: _BoardingChip(station: station)),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.eta});

  final StationEta eta;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[StationLabels.stationStatus(eta.station)];

    final line = StationLabels.eta(eta);
    if (line != null && !eta.station.hasDeparted) {
      parts.add(line);
      final source = StationLabels.etaSource(eta.confidence);
      if (source != null) parts.add(source);
    }

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CaptainTypography.labelSmall(context).copyWith(
        color: CaptainColors.textSecondaryFor(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// "2/3" — boarded over expected, at a glance, for every stop.
class _BoardingChip extends StatelessWidget {
  const _BoardingChip({required this.station});

  final TripStation station;

  @override
  Widget build(BuildContext context) {
    final complete = station.boardingResolved;
    final color = complete
        ? CaptainColors.primary
        : CaptainColors.textSecondaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Text(
        '${station.boardedCount}/${station.expectedBoardings}',
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Spine extends StatelessWidget {
  const _Spine({
    required this.color,
    required this.filled,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final bool filled;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final line = CaptainColors.dividerFor(context);

    return SizedBox(
      width: 20,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : line,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : line,
            ),
          ),
        ],
      ),
    );
  }
}

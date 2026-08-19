import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

/// Expected / boarded / still to board, as three numbers a driver can read
/// without parsing a sentence.
///
/// The counts come off the station row, which the database maintains from the
/// manifest — so what the captain sees here and what the rider sees on their
/// phone are literally the same numbers, not two independent tallies that can
/// disagree.
class StationBoardingTally extends StatelessWidget {
  const StationBoardingTally({super.key, required this.station});

  final TripStation station;

  @override
  Widget build(BuildContext context) {
    final pending = station.pendingCount;
    final noShow = station.noShowCount;

    return Row(
      children: [
        Expanded(
          child: _Cell(
            value: station.expectedBoardings,
            label: 'متوقعون',
            color: CaptainColors.textSecondaryFor(context),
          ),
        ),
        const _Separator(),
        Expanded(
          child: _Cell(
            value: station.boardedCount,
            label: 'صعدوا',
            color: CaptainColors.primary,
          ),
        ),
        const _Separator(),
        Expanded(
          child: _Cell(
            value: pending,
            label: 'لم يصعدوا',
            color: pending > 0
                ? CaptainColors.primary
                : CaptainColors.textSecondaryFor(context),
          ),
        ),
        // Only shown once someone has actually been resolved as absent — an
        // always-present "0 غياب" invites the captain to think of it as an
        // option rather than an exception.
        if (noShow > 0) ...[
          const _Separator(),
          Expanded(
            child: _Cell(
              value: noShow,
              label: 'لم يحضروا',
              color: CaptainColors.textSecondaryFor(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: CaptainTypography.headlineSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.labelSmall(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: CaptainColors.dividerFor(context),
    );
  }
}

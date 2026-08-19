import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../formatters/station_labels.dart';
import 'station_boarding_tally.dart';

/// The one thing on screen a driver should be able to read at a glance: which
/// station this is, when they were due, who is still boarding, and whether they
/// may leave.
///
/// Everything else on the trip screen is reference material. This is the answer.
class CurrentStationPanel extends StatelessWidget {
  const CurrentStationPanel({
    super.key,
    required this.station,
    required this.gate,
    required this.eta,
    required this.now,
    required this.isLast,
    this.onReportNoShow,
  });

  final TripStation station;

  /// Null while the vehicle is between stations — the panel then reads as the
  /// station being driven towards, with its estimate.
  final StationGate? gate;

  final StationEta? eta;
  final DateTime now;
  final bool isLast;

  /// Opens the controlled no-show flow. Absent unless riders are actually
  /// holding the vehicle here, so the escape hatch is never on screen when there
  /// is nothing to escape.
  final VoidCallback? onReportNoShow;

  @override
  Widget build(BuildContext context) {
    final atStation = station.isCurrent;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: CaptainDesignTokens.floatingShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(atStation: atStation, isLast: isLast),
          Padding(
            padding: const EdgeInsets.all(CaptainDesignTokens.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: CaptainColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: CaptainDesignTokens.s12),
                    Expanded(
                      child: Text(
                        station.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CaptainTypography.titleLarge(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: CaptainColors.textPrimaryFor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CaptainDesignTokens.s8),
                _TimingLine(station: station, eta: eta, atStation: atStation),
                if (station.expectedBoardings > 0) ...[
                  const SizedBox(height: CaptainDesignTokens.s16),
                  StationBoardingTally(station: station),
                ],
                if (gate != null) ...[
                  const SizedBox(height: CaptainDesignTokens.s16),
                  _GateBanner(gate: gate!, now: now),
                ],
                if (onReportNoShow != null) ...[
                  const SizedBox(height: CaptainDesignTokens.s12),
                  _NoShowLink(onPressed: onReportNoShow!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.atStation, required this.isLast});

  final bool atStation;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final label = atStation
        ? 'المحطة الحالية'
        : isLast
        ? 'الوجهة الأخيرة'
        : 'المحطة القادمة';

    return Container(
      color: CaptainColors.primary.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s20,
        vertical: CaptainDesignTokens.s12,
      ),
      child: Row(
        children: [
          Icon(
            atStation ? Icons.pin_drop_rounded : Icons.alt_route_rounded,
            size: 20,
            color: CaptainColors.primary,
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Text(
            label,
            style: CaptainTypography.titleSmall(context).copyWith(
              color: CaptainColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The planned time, and — once the vehicle is there — the time it really
/// arrived. Both, rather than one replacing the other: a captain running late
/// needs to see by how much.
class _TimingLine extends StatelessWidget {
  const _TimingLine({
    required this.station,
    required this.eta,
    required this.atStation,
  });

  final TripStation station;
  final StationEta? eta;
  final bool atStation;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    final planned = station.expectedArrivalAt;
    if (planned != null) {
      parts.add('الوصول المتوقع ${CaptainFormats.clock(planned)}');
    }

    final actual = station.actualArrivalAt;
    if (atStation && actual != null) {
      parts.add('وصلت ${CaptainFormats.clock(actual)}');
    } else if (!atStation && eta != null) {
      final line = StationLabels.eta(eta!);
      if (line != null && planned == null) parts.add(line);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: CaptainTypography.bodyMedium(context).copyWith(
        color: CaptainColors.textSecondaryFor(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// "Can I leave now?", answered in one line with a colour that carries the same
/// meaning at arm's length.
class _GateBanner extends StatelessWidget {
  const _GateBanner({required this.gate, required this.now});

  final StationGate gate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (gate.state) {
      StationGateState.ready when gate.aheadOfSchedule => (
        CaptainColors.success,
        Icons.schedule_rounded,
      ),
      StationGateState.ready => (
        CaptainColors.success,
        Icons.check_circle_rounded,
      ),
      StationGateState.waitingForPassengers => (
        CaptainColors.primary,
        Icons.people_alt_rounded,
      ),
      StationGateState.notAtStation => (
        CaptainColors.primary,
        Icons.directions_bus_filled_rounded,
      ),
    };

    final detail = StationLabels.gateDetail(gate, now);

    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: CaptainDesignTokens.br16,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  StationLabels.gateHeadline(gate),
                  style: CaptainTypography.titleSmall(context).copyWith(
                    color: CaptainColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: CaptainTypography.bodySmall(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Deliberately understated, and deliberately not called "Skip": it opens a flow
/// that asks for a reason and records it against the passenger.
class _NoShowLink extends StatelessWidget {
  const _NoShowLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_off_rounded, size: 18),
        label: const Text('راكب لم يصعد'),
        style: TextButton.styleFrom(
          foregroundColor: CaptainColors.textSecondaryFor(context),
          padding: const EdgeInsets.symmetric(
            horizontal: CaptainDesignTokens.s8,
          ),
        ),
      ),
    );
  }
}

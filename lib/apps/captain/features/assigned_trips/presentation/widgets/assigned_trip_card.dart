import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_counts.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';

import '../../domain/entities/assigned_trip.dart';
import 'assigned_trip_card_parts.dart';

class AssignedTripCard extends StatelessWidget {
  const AssignedTripCard({
    super.key,
    required this.trip,
    required this.onOpen,
    required this.onManifest,
  });

  final AssignedTrip trip;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    final isDone = trip.status == AssignedTripStatus.completed;

    return CaptainTicker(
      builder: (context, now) {
        final stage = trip.stageAt(now);
        final accent = CaptainTripStagePalette.accent(stage);

        return Container(
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br20,
            boxShadow: CaptainDesignTokens.softShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Opacity(
            opacity: isDone ? 0.72 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpen,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        CaptainDesignTokens.s20,
                        CaptainDesignTokens.s16,
                        CaptainDesignTokens.s16,
                        CaptainDesignTokens.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TimeRail(trip: trip, accent: accent),
                                const SizedBox(width: CaptainDesignTokens.s16),
                                Expanded(child: _Summary(trip: trip)),
                              ],
                            ),
                          ),
                          if (trip.passengerCount > 0) ...[
                            const SizedBox(height: CaptainDesignTokens.s12),
                            _BoardingBar(trip: trip, accent: accent),
                          ],
                          const SizedBox(height: CaptainDesignTokens.s12),
                          _Actions(
                            isDone: isDone,
                            openLabel: CaptainTripStageLabels.openAction(stage),
                            isRunning: trip.status.isRunning,
                            onOpen: onOpen,
                            onManifest: onManifest,
                          ),
                        ],
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 4, color: accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeRail extends StatelessWidget {
  const _TimeRail({required this.trip, required this.accent});

  final AssignedTrip trip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final duration = trip.expectedArrivalTime.difference(trip.departureTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CaptainFormats.clock(trip.departureTime),
              style: CaptainTypography.titleMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: CaptainColors.textPrimaryFor(context),
                height: 1.1,
              ),
            ),
            if (duration.inMinutes > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  CaptainFormats.duration(duration),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelSmall(
                    context,
                  ).copyWith(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
            Text(
              CaptainFormats.clock(trip.expectedArrivalTime),
              style: CaptainTypography.labelMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        _Track(accent: accent),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final line = CaptainColors.dividerFor(context);

    return Column(
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
        Expanded(child: Container(width: 2, color: line)),
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: line, width: 2),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                trip.route,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: CaptainColors.textPrimaryFor(context),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s8),
            TripStatusBadge(status: trip.status),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            TripFact(
              icon: Icons.directions_bus_rounded,
              text: trip.vehicleNumber.isEmpty
                  ? 'مركبة غير محددة'
                  : trip.vehicleNumber,
            ),
            if (trip.stops.isNotEmpty) ...[
              const SizedBox(width: CaptainDesignTokens.s12),
              TripFact(
                icon: Icons.alt_route_rounded,
                text: CaptainCounts.stops(trip.stops.length),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BoardingBar extends StatelessWidget {
  const _BoardingBar({required this.trip, required this.accent});

  final AssignedTrip trip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = trip.passengerCount == 0
        ? 0.0
        : trip.boardedCount / trip.passengerCount;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: CaptainDesignTokens.brPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Text(
          '${trip.boardedCount}/${trip.passengerCount} صعدوا',
          style: CaptainTypography.labelMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isDone,
    required this.openLabel,
    required this.isRunning,
    required this.onOpen,
    required this.onManifest,
  });

  final bool isDone;

  final String openLabel;
  final bool isRunning;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return CaptainButton(
        label: 'كشف الركاب',
        icon: Icons.group_rounded,
        onPressed: onManifest,
        variant: CaptainButtonVariant.outline,
        height: 46,
      );
    }

    return Row(
      children: [
        Expanded(
          child: CaptainButton(
            label: openLabel,
            icon: isRunning
                ? Icons.play_arrow_rounded
                : Icons.info_outline_rounded,
            onPressed: onOpen,
            height: 46,
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        _ManifestIconButton(onTap: onManifest),
      ],
    );
  }
}

class _ManifestIconButton extends StatelessWidget {
  const _ManifestIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'كشف الركاب',
      child: Semantics(
        button: true,
        label: 'كشف الركاب',
        child: SizedBox(
          width: 46,
          height: 46,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: CaptainDesignTokens.br16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: CaptainDesignTokens.br16,
                  border: Border.all(color: scheme.outline),
                ),
                child: Icon(
                  Icons.group_rounded,
                  size: 20,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

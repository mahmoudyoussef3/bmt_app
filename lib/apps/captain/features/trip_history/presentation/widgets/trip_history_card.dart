import 'package:flutter/material.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import '../../domain/entities/trip_history_item.dart';
import '../utils/trip_history_palette.dart';
import 'trip_history_boarding_bar.dart';
import 'trip_history_chip.dart';
import 'trip_history_time_strip.dart';

class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({super.key, required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final missing = trip.passengerCount - trip.boardedCount;

    return CaptainCard(
      padding: EdgeInsets.zero,
      onTap: () => context.openTripHistoryDetail(trip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(trip: trip),
          Padding(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            child: Column(
              children: [
                TripHistoryTimeStrip(
                  departure: trip.departureTime,
                  arrival: trip.arrivalTime,
                  duration: trip.duration,
                ),
                const SizedBox(height: CaptainDesignTokens.s16),
                TripHistoryBoardingBar(
                  boarded: trip.boardedCount,
                  total: trip.passengerCount,
                ),
                if (missing > 0) ...[
                  const SizedBox(height: CaptainDesignTokens.s8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TripHistoryChip(
                      icon: Icons.person_off_rounded,
                      color: TripHistoryPalette.attention,
                    ),
                  ),
                ],
                _VehicleFooter(trip: trip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: TripHistoryPalette.wash(context),
        borderRadius: const BorderRadius.vertical(top: CaptainDesignTokens.r24),
      ),
      child: Row(
        children: [
          _RouteMark(boarded: trip.boardedCount, total: trip.passengerCount),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.titleSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  CaptainFormats.dayAndMonth(trip.tripDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelMedium(
                    context,
                  ).copyWith(color: TripHistoryPalette.neutral(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: TripHistoryPalette.neutral(context),
          ),
        ],
      ),
    );
  }
}

class _RouteMark extends StatelessWidget {
  const _RouteMark({required this.boarded, required this.total});

  final int boarded;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CaptainColors.primary,
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: const Icon(
        Icons.route_rounded,
        size: 20,
        color: CaptainColors.onPrimary,
      ),
    );
  }
}

class _VehicleFooter extends StatelessWidget {
  const _VehicleFooter({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (trip.vehicleNumber.isNotEmpty)
        TripHistoryChip(
          icon: Icons.directions_bus_rounded,
          color: TripHistoryPalette.neutral(context),
        ),
      if (trip.plateNumber.isNotEmpty)
        TripHistoryChip(
          icon: Icons.confirmation_number_rounded,
          color: TripHistoryPalette.neutral(context),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: CaptainDesignTokens.s12),
        Divider(
          height: 1,
          thickness: 1,
          color: CaptainColors.dividerFor(context).withValues(alpha: 0.7),
        ),
        const SizedBox(height: CaptainDesignTokens.s12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: CaptainDesignTokens.s8,
            runSpacing: CaptainDesignTokens.s8,
            children: chips,
          ),
        ),
      ],
    );
  }
}

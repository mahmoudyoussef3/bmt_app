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

/// One completed trip in the history list.
///
/// The card carries no "مكتملة" badge any more. It sat on every row of a
/// screen whose whole subject is completed trips, so it marked nothing while
/// taking the loudest colour on the card; that space now goes to the trip's
/// date, which actually tells one row from another.
class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({super.key, required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
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
                  trailing: trip.vehicleNumber.isEmpty
                      ? null
                      : TripHistoryChip(
                          icon: Icons.directions_bus_rounded,
                          label: trip.vehicleNumber,
                          color: TripHistoryPalette.neutral(context),
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
          const _RouteMark(),
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
            Icons.chevron_left_rounded,
            size: 20,
            color: TripHistoryPalette.neutral(context),
          ),
        ],
      ),
    );
  }
}

/// The brand mark standing in for a trip, so a scanned list reads as a column
/// of routes rather than a column of text.
class _RouteMark extends StatelessWidget {
  const _RouteMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: TripHistoryPalette.markGradient,
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

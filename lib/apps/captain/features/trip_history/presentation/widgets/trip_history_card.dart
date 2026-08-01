import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../../domain/entities/trip_history_item.dart';
import '../utils/trip_history_labels.dart';
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
///
/// What still varies between rows is the boarding outcome and the bus, so the
/// card is built around those: the mark takes the outcome's colour, a shortfall
/// is named rather than left to be subtracted, and the vehicle's two
/// identifiers — fleet number and plate — sit in their own footer instead of
/// one of them being dropped for space.
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
                // The seats that never boarded, named rather than left as a
                // subtraction. On its own line, not beside the boarded count:
                // the two would then compete for one row's width, and at an
                // enlarged system font the line the captain actually reads is
                // the one that would lose.
                if (missing > 0) ...[
                  const SizedBox(height: CaptainDesignTokens.s8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TripHistoryChip(
                      icon: Icons.person_off_rounded,
                      label: TripHistoryLabels.notBoarded(missing),
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
          // Mirrored to point left by the app's RTL — see `CaptainListRow`.
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

/// The mark standing in for a trip, so a scanned list reads as a column of
/// routes rather than a column of text — and, by its colour, tells a trip that
/// boarded everyone from one that did not.
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
        gradient: TripHistoryPalette.mark(boarded: boarded, total: total),
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

/// Which bus ran the trip — both of the ways it is identified.
///
/// The fleet number is what operations says on the radio; the plate is what is
/// written on the vehicle. The card used to show only the first, so a captain
/// checking a finished trip against a logbook had to open the detail page for
/// the number actually printed on the bus.
class _VehicleFooter extends StatelessWidget {
  const _VehicleFooter({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (trip.vehicleNumber.isNotEmpty)
        TripHistoryChip(
          icon: Icons.directions_bus_rounded,
          label: trip.vehicleNumber,
          color: TripHistoryPalette.neutral(context),
        ),
      if (trip.plateNumber.isNotEmpty)
        TripHistoryChip(
          icon: Icons.confirmation_number_rounded,
          label: trip.plateNumber,
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
        // Wrapped rather than laid out in a Row: an Egyptian plate and a fleet
        // code both run long, and at an enlarged system font the pair stops
        // fitting on one line long before either of them is worth truncating.
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

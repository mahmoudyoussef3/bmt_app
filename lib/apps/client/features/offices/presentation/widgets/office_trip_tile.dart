import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_trip.dart';

/// One departure this office is selling: when it leaves, the corridor it runs,
/// what a seat costs and how many are left.
///
/// A sold-out departure stays listed but stops being tappable — a rider learns
/// the bus exists and fills up, which is what brings them back earlier next
/// time.
class OfficeTripTile extends StatelessWidget {
  const OfficeTripTile({super.key, required this.trip, required this.onTap});

  final OfficeTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final time = formatTripTime(context, trip.departureTime);
    final day = formatTripDay(context, trip.tripDate);

    return ClientCard(
      onTap: trip.isSoldOut ? null : onTap,
      padding: const EdgeInsets.all(ClientSpacing.sm),
      child: Row(
        children: [
          _DepartureStamp(time: time, day: day, soldOut: trip.isSoldOut),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      size: 14,
                      color: _seatColor(trip),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        trip.isSoldOut
                            ? l10n.common_soldOut
                            : l10n.home_seatsAvailable(trip.seatsLeft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.labelSmall(
                          context,
                        ).copyWith(color: _seatColor(trip)),
                      ),
                    ),
                    if (trip.duration.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: ClientColors.textTertiaryFor(context),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trip.duration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: ClientColors.textTertiaryFor(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.price.isEmpty ? l10n.home_fareNotPublished : trip.price,
                style: trip.price.isEmpty
                    ? ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textTertiaryFor(context))
                    : ClientTypography.priceSmall(
                        context,
                      ).copyWith(color: scheme.primary),
              ),
              if (!trip.isSoldOut) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.home_bookSeat,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The departure time as a ticket stamp — the one thing a rider scans a
/// departure board for, so it gets the strongest position on the tile.
class _DepartureStamp extends StatelessWidget {
  const _DepartureStamp({
    required this.time,
    required this.day,
    required this.soldOut,
  });

  final String time;
  final String day;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final accent = soldOut
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.primaryFor(context);

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            time.isEmpty ? '—' : time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelLarge(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w900),
          ),
          if (day.isNotEmpty)
            Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
        ],
      ),
    );
  }
}

Color _seatColor(OfficeTrip trip) {
  if (trip.isSoldOut) return ClientColors.journeyRed;
  return trip.hasScarceSeats
      ? ClientColors.journeyAmber
      : ClientColors.journeyCyan;
}

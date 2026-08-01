import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../domain/entities/office_trip.dart';

/// One departure this office is selling: when it leaves, the corridor it runs,
/// what a seat costs and how many are left.
///
/// The date is carried by the day heading above the group, so the tile spends
/// its strongest position on the clock time — the one field a rider scans a
/// departure board for.
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
    final soldOut = trip.isSoldOut;
    final accent = ClientColors.primaryFor(context);

    return ClientCard(
      onTap: soldOut ? null : onTap,
      padding: const EdgeInsets.all(ClientSpacing.sm),
      backgroundColor: soldOut
          ? ClientColors.surfaceSubtleFor(context)
          : ClientColors.surfaceFor(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DepartureStamp(
            time: formatTripTime(context, trip.departureTime),
            soldOut: soldOut,
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: soldOut
                        ? ClientColors.textSecondaryFor(context)
                        : ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: ClientSpacing.xs,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SeatsPill(trip: trip),
                    if (trip.duration.isNotEmpty)
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: trip.duration,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          // Capped so the fare column cannot starve the route and seat block
          // beside it: a long Arabic "fare not published" used to squeeze the
          // middle of the tile down to a few pixels on a 320pt phone.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.price.isEmpty ? l10n.home_fareNotPublished : trip.price,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: trip.price.isEmpty
                      ? ClientTypography.labelSmall(
                          context,
                        ).copyWith(color: ClientColors.textTertiaryFor(context))
                      : ClientTypography.priceSmall(context).copyWith(
                          color: soldOut
                              ? ClientColors.textTertiaryFor(context)
                              : accent,
                        ),
                ),
                if (!soldOut) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.home_bookSeat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      DirectionalIcon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: accent,
                      ),
                    ],
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

/// The departure time as a ticket stamp.
class _DepartureStamp extends StatelessWidget {
  const _DepartureStamp({required this.time, required this.soldOut});

  final String time;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final accent = soldOut
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.primaryFor(context);

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.departure_board_rounded, size: 14, color: accent),
          const SizedBox(height: 3),
          Text(
            time.isEmpty ? '—' : time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// Seat availability, coloured by how urgent it is: red once the bus is full,
/// amber while the last few seats go, cyan while there is room.
class _SeatsPill extends StatelessWidget {
  const _SeatsPill({required this.trip});

  final OfficeTrip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = trip.isSoldOut
        ? ClientColors.journeyRed
        : trip.hasScarceSeats
        ? ClientColors.journeyAmber
        : ClientColors.journeyCyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_seat_rounded, size: 12, color: color),
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
              ).copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = ClientColors.textTertiaryFor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.all(ClientSpacing.md),
      backgroundColor: soldOut
          ? ClientColors.surfaceSubtleFor(context)
          : ClientColors.surfaceFor(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: _DepartureStamp(
              time: formatTripTime(context, trip.departureTime),
              soldOut: soldOut,
            ),
          ),
          Container(
            width: 1,
            height: 56,
            color: ClientColors.borderFor(context).withAlpha(150),
            margin: const EdgeInsets.only(right: ClientSpacing.md),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: soldOut
                        ? ClientColors.textSecondaryFor(context)
                        : ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 8),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trip.price.isEmpty ? l10n.home_fareNotPublished : trip.price,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: trip.price.isEmpty
                    ? ClientTypography.labelSmall(context).copyWith(
                        color: ClientColors.textTertiaryFor(context),
                      )
                    : ClientTypography.priceMedium(context).copyWith(
                        color: soldOut
                            ? ClientColors.textTertiaryFor(context)
                            : accent,
                      ),
              ),
              if (!soldOut) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(ClientRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.home_bookSeat,
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      DirectionalIcon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: accent,
                      ),
                    ],
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

class _DepartureStamp extends StatelessWidget {
  const _DepartureStamp({required this.time, required this.soldOut});

  final String time;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final color = soldOut
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.textPrimaryFor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time.isEmpty ? '—' : time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingMedium(context).copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
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
              style: ClientTypography.labelSmall(context).copyWith(
                color: color, 
                fontWeight: FontWeight.w800,
              ),
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
    final muted = ClientColors.textSecondaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(context).copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

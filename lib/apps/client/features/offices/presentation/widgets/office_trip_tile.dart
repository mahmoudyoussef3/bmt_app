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
/// Drawn as a ticket torn across the middle. Above the tear is the decision —
/// the clock time, the corridor, the fare; below it the conditions and the way
/// in. Everything used to compete for one horizontal line, which overflowed the
/// card on a 320px screen the moment an Arabic route name met a fare and a
/// button.
///
/// The date is carried by the day heading above the group, so the tile spends
/// its strongest position on the clock time — the one field a rider scans a
/// departure board for.
///
/// A sold-out departure stays listed but stops being tappable: a rider learns
/// the bus exists and fills up, which is what brings them back earlier next
/// time.
class OfficeTripTile extends StatelessWidget {
  const OfficeTripTile({super.key, required this.trip, required this.onTap});

  final OfficeTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = trip.isSoldOut;

    return ClientCard(
      onTap: soldOut ? null : onTap,
      padding: EdgeInsets.zero,
      backgroundColor: soldOut
          ? ClientColors.surfaceSubtleFor(context)
          : ClientColors.surfaceFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClientSpacing.md,
              ClientSpacing.md,
              ClientSpacing.md,
              ClientSpacing.sm,
            ),
            child: _Headline(trip: trip),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClientSpacing.md),
            child: DashedDivider(
              color: ClientColors.borderFor(context).withAlpha(150),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClientSpacing.md,
              ClientSpacing.sm,
              ClientSpacing.md,
              ClientSpacing.md,
            ),
            child: _Footline(trip: trip, onTap: onTap),
          ),
        ],
      ),
    );
  }
}

/// Time, fare, corridor — the three fields a rider compares departures on.
///
/// The clock and the fare take the top line and nothing else does: they are the
/// two figures the eye jumps between down a board, and a route name wedged
/// between them shortened both. The corridor gets the full width underneath,
/// which is what long Arabic city names need anyway.
///
/// Both figures are [Flexible] so a long 12-hour clock and a four-digit fare
/// shorten instead of overflowing the card at large text sizes.
class _Headline extends StatelessWidget {
  const _Headline({required this.trip});

  final OfficeTrip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: _DepartureStamp(
                time: formatTripTime(context, trip.departureTime),
                soldOut: trip.isSoldOut,
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            Flexible(child: _Fare(trip: trip)),
          ],
        ),
        const SizedBox(height: ClientSpacing.sm),
        _Corridor(trip: trip),
      ],
    );
  }
}

/// Seat scarcity and ride length on one side, the way in on the other.
class _Footline extends StatelessWidget {
  const _Footline({required this.trip, required this.onTap});

  final OfficeTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: ClientSpacing.xs,
            runSpacing: ClientSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SeatsPill(trip: trip),
              if (trip.duration.isNotEmpty)
                _MetaChip(icon: Icons.schedule_rounded, label: trip.duration),
            ],
          ),
        ),
        if (!trip.isSoldOut) ...[
          const SizedBox(width: ClientSpacing.xs),
          _BookCta(onTap: onTap),
        ],
      ],
    );
  }
}

/// The clock time in a tinted block — a stamp on the ticket, and the anchor the
/// eye lands on when scanning a column of departures.
class _DepartureStamp extends StatelessWidget {
  const _DepartureStamp({required this.time, required this.soldOut});

  final String time;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final onSurface = soldOut
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.onPrimaryContainerFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: soldOut
            ? ClientColors.surfaceMutedFor(context)
            : ClientColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Text(
        time.isEmpty ? '—' : time,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.headingSmall(
          context,
        ).copyWith(color: onSurface, fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// The corridor, named the way the office named it — with the endpoints spelled
/// out underneath only when the name does not already say them.
class _Corridor extends StatelessWidget {
  const _Corridor({required this.trip});

  final OfficeTrip trip;

  bool get _endpointsAddSomething {
    if (trip.pickup.isEmpty || trip.destination.isEmpty) return false;
    return !(trip.routeName.contains(trip.pickup) &&
        trip.routeName.contains(trip.destination));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          trip.routeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            color: trip.isSoldOut
                ? ClientColors.textSecondaryFor(context)
                : ClientColors.textPrimaryFor(context),
          ),
        ),
        if (_endpointsAddSomething) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Flexible(
                child: Text(
                  trip.pickup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ),
              const SizedBox(width: 4),
              DirectionalIcon(
                Icons.arrow_forward_rounded,
                size: 11,
                color: ClientColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  trip.destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// What a seat costs. An office that has not published a fare says so rather
/// than showing a zero.
class _Fare extends StatelessWidget {
  const _Fare({required this.trip});

  final OfficeTrip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.price.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 96),
        child: Text(
          context.l10n.home_fareNotPublished,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
      );
    }

    return Text(
      trip.price,
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ClientTypography.priceMedium(context).copyWith(
        color: trip.isSoldOut
            ? ClientColors.textTertiaryFor(context)
            : ClientColors.primaryFor(context),
      ),
    );
  }
}

/// The way in. The whole card is tappable; this is what tells a rider so.
class _BookCta extends StatelessWidget {
  const _BookCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          
          color: ClientColors.primaryFillFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.home_bookSeat,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            const DirectionalIcon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
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
        ? ClientColors.journeyRedFor(context)
        : trip.hasScarceSeats
        ? ClientColors.journeyAmberFor(context)
        : ClientColors.journeyCyanFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trip.isSoldOut
                ? Icons.do_not_disturb_on_rounded
                : Icons.event_seat_rounded,
            size: 12,
            color: color,
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
    final muted = ClientColors.textSecondaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../domain/entities/route_availability.dart';
import '../../domain/entities/route_summary.dart';

/// One corridor in the routes catalog, as an origin→destination spine with
/// its distance/duration and operating office underneath.
///
/// Drawn the same way [OfficeRouteTile] draws a corridor: two endpoints are
/// two lines, not one ellipsised "A → B" that loses the destination on a
/// narrow phone with long Arabic city names.
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
    this.viaStop = '',
  });

  final RouteSummary route;

  /// An intermediate stop the rider's search matched — captioned under the
  /// endpoints so the corridor explains itself. Empty when the route matched
  /// on something the card already shows, or when nothing was searched at all.
  final String viaStop;

  final VoidCallback onTap;

  bool get _hasEndpoints =>
      route.startCity.isNotEmpty && route.endCity.isNotEmpty;

  bool get _hasMeta => route.distance.isNotEmpty || route.duration.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasEndpoints) ...[
                _RouteSpine(accent: accent),
                const SizedBox(width: ClientSpacing.md),
              ] else ...[
                Icon(Icons.route_rounded, color: accent),
                const SizedBox(width: ClientSpacing.md),
              ],
              Expanded(
                child: _hasEndpoints
                    ? _Endpoints(route: route)
                    : Text(
                        route.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.bodyMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: ClientSpacing.xs),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClientColors.primaryContainerFor(context),
                ),
                child: DirectionalIcon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: ClientColors.onPrimaryContainerFor(context),
                ),
              ),
            ],
          ),
          if (viaStop.isNotEmpty) ...[
            const SizedBox(height: ClientSpacing.sm),
            _ViaStopTag(stopName: viaStop),
          ],
          if (route.availability.isKnown) ...[
            const SizedBox(height: ClientSpacing.sm),
            _AvailabilityRow(availability: route.availability),
          ],
          if (_hasMeta || route.officeName.isNotEmpty) ...[
            const SizedBox(height: ClientSpacing.sm),
            Row(
              children: [
                if (route.distance.isNotEmpty)
                  _MetaChip(icon: Icons.route_outlined, label: route.distance),
                if (route.distance.isNotEmpty && route.duration.isNotEmpty)
                  const SizedBox(width: ClientSpacing.xs),
                if (route.duration.isNotEmpty)
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: route.duration,
                  ),
                if (route.officeName.isNotEmpty) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      route.officeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: ClientColors.textTertiaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Whether this corridor is selling seats, stated on the card so the rider
/// never has to open a route to find out that it is dead.
///
/// Reads as a badge plus the one fact that follows from it: when the next bus
/// leaves. Sold out keeps that line — a full corridor is still worth knowing
/// the shape of — while a corridor with nothing on sale says only that, because
/// there is no departure to name.
class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.availability});

  final RouteAvailability availability;

  /// Below this, the seat count stops being background detail and becomes the
  /// reason to book now, so it is worth the space on the card.
  static const int _scarceSeats = 5;

  /// "Next departure Today · 8:00 AM" — composed through the translation so the
  /// separator sits where the language puts it, not where Dart concatenated it.
  String _departureLine(BuildContext context) {
    final day = formatTripDay(context, availability.nextDepartureDate);
    if (day.isEmpty) return '';

    final time = formatTripTime(context, availability.nextDepartureTime);
    if (time.isEmpty) return context.l10n.routes_nextDepartureDay(day);
    return context.l10n.routes_nextDepartureDayTime(day, time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final departure = availability.status == RouteAvailabilityStatus.none
        ? ''
        : _departureLine(context);
    final showSeats =
        availability.isBookable &&
        availability.seatsLeft > 0 &&
        availability.seatsLeft <= _scarceSeats;

    return Row(
      children: [
        _AvailabilityPill(status: availability.status),
        if (departure.isNotEmpty) ...[
          const SizedBox(width: ClientSpacing.xs),
          Expanded(
            child: Text(
              departure,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
        ],
        if (showSeats) ...[
          const SizedBox(width: ClientSpacing.xs),
          Text(
            l10n.routes_seatsLeft(availability.seatsLeft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.journeyAmberFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

/// The badge itself. Three states, because "every seat is taken" and "no bus is
/// running" send a rider to different places — one comes back tomorrow, the
/// other looks for another operator.
class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.status});

  final RouteAvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final (
      ClientJourneyStatus tone,
      IconData icon,
      String label,
    ) = switch (status) {
      RouteAvailabilityStatus.bookable => (
        ClientJourneyStatus.upcoming,
        Icons.event_available_rounded,
        l10n.routes_availabilityBookable,
      ),
      RouteAvailabilityStatus.soldOut => (
        ClientJourneyStatus.departing,
        Icons.event_busy_rounded,
        l10n.routes_availabilitySoldOut,
      ),
      // Never rendered — the card omits the whole row when the outlook is
      // unknown — but the switch stays total rather than throwing.
      RouteAvailabilityStatus.unknown || RouteAvailabilityStatus.none => (
        ClientJourneyStatus.completed,
        Icons.event_note_outlined,
        l10n.routes_availabilityNone,
      ),
    };

    final colors = ClientColors.journeyBadgeFor(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.label),
          const SizedBox(width: 5),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: colors.fg, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// "يمر عبر بنها" — why this corridor is in the results when neither of its
/// endpoints is what the rider typed.
///
/// Sits below the endpoints rather than beside them: a stop on the way is a
/// fact about the journey, not a third terminus, and putting it on the spine
/// would read as one. Hugs its text so it reads as a tag on the card, not as
/// another field.
class _ViaStopTag extends StatelessWidget {
  const _ViaStopTag({required this.stopName});

  final String stopName;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withAlpha(20),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined, size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.routes_viaStation(stopName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ClientColors.textTertiaryFor(context)),
          const SizedBox(width: 4),
          Text(
            label,
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

class _Endpoints extends StatelessWidget {
  const _Endpoints({required this.route});

  final RouteSummary route;

  /// Offices commonly name a route after its endpoints; repeating that above
  /// the spine would be the same fact twice.
  bool get _nameAddsSomething {
    final name = route.name.trim();
    if (name.isEmpty) return false;
    return !(name.contains(route.startCity) && name.contains(route.endCity));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = ClientTypography.bodyMedium(
      context,
    ).copyWith(fontWeight: FontWeight.w800, height: 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_nameAddsSomething) ...[
          Text(
            route.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          route.startCity,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          route.endCity,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
      ],
    );
  }
}

/// Dot — line — dot, the corridor as a diagram.
class _RouteSpine extends StatelessWidget {
  const _RouteSpine({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: accent, filled: false),
        Container(
          width: 3,
          height: 24,
          color: accent.withAlpha(100),
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        _Dot(color: accent, filled: true),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: filled ? 0 : 3),
      ),
    );
  }
}

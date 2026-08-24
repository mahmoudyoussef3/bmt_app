import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/route_availability.dart';
import '../../domain/entities/route_summary.dart';

/// The corridor content shared by every place a rider meets one route: Home's
/// featured shelf ([HomeFeaturedRouteCard]) and the routes catalog
/// ([RouteCard]) are the same card at two sizes, not two drawings of the same
/// data — the way [OfficeCardBody] already unifies operators.
///
/// Read top to bottom in the order a rider asks: where does it go (the
/// direction), which towns does it touch (the via line), how far and how long
/// (the meta line), then — under a rule, because this is the part they decide
/// on — who runs it, whether it is selling, and when it next leaves.
///
/// The endpoints are one composed [RouteDirectionText] line rather than two
/// stacked names: the arrow is what makes a corridor read as a journey with a
/// direction. Long Arabic city names are given a second line in the catalog
/// ([dense] `false`) so nothing is ellipsised away on a narrow phone.
class RouteCardBody extends StatelessWidget {
  const RouteCardBody({
    super.key,
    required this.route,
    this.viaStop = '',
    this.dense = false,
  });

  final RouteSummary route;

  /// An intermediate stop the rider's *search* matched — captioned as a tag so
  /// the corridor explains why it is in the results. Empty when the route
  /// matched on something the card already shows, or when nothing was searched
  /// at all. Home never searches, so its shelf never sets this.
  final String viaStop;

  /// Tighter type and a single-line direction for Home's narrower shelf; the
  /// catalog card gets the roomier defaults, its route name, and the searched
  /// via-stop tag.
  final bool dense;

  /// The corridor's intermediate stops — every stop but the two endpoints — in
  /// running order.
  List<String> get _viaStops {
    if (route.stops.length <= 2) return const [];
    final ordered = [...route.stops]
      ..sort((a, b) => a.order.compareTo(b.order));
    return [
      for (final stop in ordered.sublist(1, ordered.length - 1)) stop.name,
    ];
  }

  bool get _hasEndpoints =>
      route.startCity.isNotEmpty && route.endCity.isNotEmpty;

  bool get _hasMeta => route.distance.isNotEmpty || route.duration.isNotEmpty;

  /// Offices commonly name a route after its endpoints; repeating that above
  /// the direction line would be the same fact twice. Home drops the name
  /// either way — its shelf states the corridor, not the office's label for it.
  bool get _nameAddsSomething {
    if (dense || !_hasEndpoints) return false;
    final name = route.name.trim();
    if (name.isEmpty) return false;
    return !(name.contains(route.startCity) && name.contains(route.endCity));
  }

  @override
  Widget build(BuildContext context) {
    final via = _viaStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_nameAddsSomething) ...[
          Text(
            route.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
          const SizedBox(height: 4),
        ],
        _DirectionRow(route: route, dense: dense, hasEndpoints: _hasEndpoints),
        if (via.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ViaStopsLine(stops: via),
        ],
        if (_hasMeta) ...[
          const SizedBox(height: ClientSpacing.sm),
          _MetaLine(route: route),
        ],
        if (viaStop.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.sm),
          _SearchedStopTag(stopName: viaStop),
        ],
        const SizedBox(height: ClientSpacing.sm),
        Divider(height: 1, color: ClientColors.borderFor(context)),
        const SizedBox(height: ClientSpacing.sm),
        Row(
          children: [
            if (route.officeName.isNotEmpty)
              Flexible(
                child: _OperatorMark(
                  name: route.officeName,
                  logoUrl: route.officeLogoUrl,
                ),
              ),
            const Spacer(),
            _AvailabilityPill(status: route.availability.status),
          ],
        ),
        if (route.availability.isKnown) _NextDeparture(route: route),
      ],
    );
  }
}

/// `Cairo → Mansoura`, the corridor as one directional line, with the chevron
/// that says the card is a door.
class _DirectionRow extends StatelessWidget {
  const _DirectionRow({
    required this.route,
    required this.dense,
    required this.hasEndpoints,
  });

  final RouteSummary route;
  final bool dense;
  final bool hasEndpoints;

  @override
  Widget build(BuildContext context) {
    final style =
        (dense
                ? ClientTypography.bodyMedium(context)
                : ClientTypography.bodyLarge(context))
            .copyWith(fontWeight: FontWeight.w800, height: 1.3);

    return Row(
      children: [
        Expanded(
          child: hasEndpoints
              ? RouteDirectionText(
                  origin: route.startCity,
                  destination: route.endCity,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                )
              : Text(
                  route.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
        ),
        const SizedBox(width: ClientSpacing.xs),
        Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: ClientColors.textTertiaryFor(context),
        ),
      ],
    );
  }
}

/// The towns the corridor passes through, pinned on one line. What turns two
/// endpoints into a route a rider can actually board halfway along.
class _ViaStopsLine extends StatelessWidget {
  const _ViaStopsLine({required this.stops});

  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.place_rounded,
          size: 14,
          color: ClientColors.textTertiaryFor(context),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            context.l10n.home_viaStations(stops.join(' · ')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ],
    );
  }
}

/// How far and how long, as plain captions rather than tinted chips — they are
/// background detail on a card whose decision lives under the rule.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.route});

  final RouteSummary route;

  @override
  Widget build(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);
    final style = ClientTypography.labelSmall(context).copyWith(color: muted);

    return Row(
      children: [
        if (route.distance.isNotEmpty)
          Flexible(
            child: _MetaItem(
              icon: Icons.route_outlined,
              label: route.distance,
              style: style,
              color: muted,
            ),
          ),
        if (route.distance.isNotEmpty && route.duration.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('·', style: style),
          ),
        if (route.duration.isNotEmpty)
          Flexible(
            child: _MetaItem(
              icon: Icons.schedule_rounded,
              label: route.duration,
              style: style,
              color: muted,
            ),
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.style,
    required this.color,
  });

  final IconData icon;
  final String label;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// "يمر عبر بنها" — why this corridor is in the results when neither of its
/// endpoints is what the rider typed.
///
/// Hugs its text so it reads as a tag on the card, not as another field, and
/// is tinted where the via-stops line above it is grey: one is a fact about the
/// route, this one is a fact about the *search*.
class _SearchedStopTag extends StatelessWidget {
  const _SearchedStopTag({required this.stopName});

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

/// Who runs the corridor: the office's own mark, a brand check, and its name.
///
/// The check states a fact true of every operator listed — each one passed
/// platform onboarding before its routes could be sold here — rather than
/// singling any one office out, the same claim [OfficeHeroBanner] makes.
class _OperatorMark extends StatelessWidget {
  const _OperatorMark({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OperatorAvatar(logoUrl: logoUrl, size: _size),
        const SizedBox(width: 6),
        Icon(
          Icons.verified_rounded,
          size: 15,
          color: ClientColors.primaryFor(context),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// The office's picture when it has uploaded one, a storefront glyph when it
/// has not — never a broken-image tile, the same answer [OfficeLogoAvatar]
/// gives on every other screen that draws an operator.
///
/// Deliberately not the office's initials: they read as a brand mark only for
/// a Latin acronym, and an Arabic trading name ("شركة الدلتا للنقل") reduces
/// to two disconnected letters that identify nothing.
class _OperatorAvatar extends StatelessWidget {
  const _OperatorAvatar({required this.logoUrl, required this.size});

  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClientColors.primaryContainerFor(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.storefront_rounded,
        size: size * 0.52,
        color: ClientColors.onPrimaryContainerFor(context),
      ),
    );

    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Whether this corridor is selling seats, stated on the card so the rider
/// never has to open a route to find out that it is dead.
///
/// Three states, because "every seat is taken" and "no bus is running" send a
/// rider to different places — one comes back tomorrow, the other looks for
/// another operator. An unread outlook renders nothing rather than guessing: a
/// wrong "unavailable" costs the office a sale, and a wrong "available" costs
/// the rider a trip.
class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.status});

  final RouteAvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == RouteAvailabilityStatus.unknown) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final (ClientJourneyStatus tone, String label) = switch (status) {
      RouteAvailabilityStatus.bookable => (
        ClientJourneyStatus.upcoming,
        l10n.routes_availabilityBookable,
      ),
      RouteAvailabilityStatus.soldOut => (
        ClientJourneyStatus.departing,
        l10n.routes_availabilitySoldOut,
      ),
      RouteAvailabilityStatus.none || RouteAvailabilityStatus.unknown => (
        ClientJourneyStatus.completed,
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
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors.label,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: colors.fg, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// When the next bus actually leaves, and — only when they are nearly gone —
/// how many seats are left on it.
///
/// The day is always named rather than assumed to be today: a corridor whose
/// soonest departure is tomorrow is a different answer to "can I travel now?".
/// Sold out keeps the line — a full corridor is still worth knowing the shape
/// of — while a corridor with nothing on sale has no departure to name.
class _NextDeparture extends StatelessWidget {
  const _NextDeparture({required this.route});

  final RouteSummary route;

  /// Below this, the seat count stops being background detail and becomes the
  /// reason to book now, so it is worth the space on the card.
  static const int _scarceSeats = 5;

  String _departureLine(BuildContext context) {
    final availability = route.availability;
    if (availability.status == RouteAvailabilityStatus.none) return '';

    final day = formatTripDay(context, availability.nextDepartureDate);
    if (day.isEmpty) return '';

    final time = formatTripTime(context, availability.nextDepartureTime);
    if (time.isEmpty) return context.l10n.routes_nextDepartureDay(day);
    return context.l10n.routes_nextDepartureDayTime(day, time);
  }

  @override
  Widget build(BuildContext context) {
    final availability = route.availability;
    final departure = _departureLine(context);
    final showSeats =
        availability.isBookable &&
        availability.seatsLeft > 0 &&
        availability.seatsLeft <= _scarceSeats;

    if (departure.isEmpty && !showSeats) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (departure.isNotEmpty)
            Expanded(
              child: Text(
                departure,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            )
          else
            const Spacer(),
          if (showSeats) ...[
            const SizedBox(width: ClientSpacing.xs),
            Text(
              context.l10n.routes_seatsLeft(availability.seatsLeft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(context).copyWith(
                color: ClientColors.journeyAmberFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

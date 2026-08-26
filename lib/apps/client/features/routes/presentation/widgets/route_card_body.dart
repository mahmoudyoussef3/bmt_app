import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_brand_avatar.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/route_availability.dart';
import '../../domain/entities/route_summary.dart';

/// The corridor content shared by every place a rider meets one route: Home's
/// featured shelf ([HomeFeaturedRouteCard]) and the routes catalog
/// ([RouteCard]) are the same card at two sizes, not two drawings of the same
/// data — the way [OfficeCardBody] already unifies operators.
///
/// Read top to bottom in the order a rider asks: where does it go (the
/// direction), which towns does it touch (the via line), how long and how far
/// (the meta line), then — under a rule, because this is the part they decide
/// on — whether it is selling and who runs it.
///
/// The endpoints are one composed [RouteDirectionText] line rather than two
/// stacked names: the arrow is what makes a corridor read as a journey with a
/// direction, and it is picked from the ambient [Directionality] so it points
/// origin→destination in Arabic and English alike. Long Arabic city names are
/// given a second line in the catalog ([dense] `false`) so nothing is
/// ellipsised away on a narrow phone.
///
/// Nothing on the card is a hardcoded string: every label comes from `l10n`,
/// and the two glyphs that mean *forward* ride on [DirectionalIcon] /
/// [routeDirectionLabel] rather than being drawn pointing right and left alone.
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

  /// A tighter, single-line direction for Home's narrower shelf; the catalog
  /// card gets the roomier heading, its route name, and the searched via-stop
  /// tag. Everything below the direction line is printed at one size in both,
  /// so a corridor is recognisably the same card on either screen.
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
        if (_hasMeta) ...[const SizedBox(height: 10), _MetaLine(route: route)],
        if (viaStop.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.sm),
          _SearchedStopTag(stopName: viaStop),
        ],
        const SizedBox(height: ClientSpacing.sm),
        Divider(height: 1, color: ClientColors.borderFor(context)),
        const SizedBox(height: ClientSpacing.sm),
        _DecisionRow(route: route),
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
                ? ClientTypography.bodyLarge(context)
                : ClientTypography.headingSmall(context))
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
        // Points *out* of the card — rightwards in English, leftwards in
        // Arabic. `chevron_right_rounded` carries `matchTextDirection`, so
        // [DirectionalIcon] hands it to [Icon] to mirror rather than flipping
        // it a second time and cancelling the mirror out.
        DirectionalIcon(
          Icons.chevron_right_rounded,
          size: 22,
          color: ClientColors.textTertiaryFor(context),
        ),
      ],
    );
  }
}

/// The towns the corridor passes through, on one line under the endpoints.
/// What turns two endpoints into a route a rider can actually board halfway
/// along.
///
/// Plain text rather than an icon-led row: it is a continuation of the
/// direction line above it — "Cairo → Tanta, *via Giza*" — and a pin in front
/// of it made the card read as a form with three labelled fields.
class _ViaStopsLine extends StatelessWidget {
  const _ViaStopsLine({required this.stops});

  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.home_viaStations(stops.join(' · ')),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ClientTypography.bodySmall(
        context,
      ).copyWith(color: ClientColors.textSecondaryFor(context)),
    );
  }
}

/// How long and how far, as plain captions rather than tinted chips — they are
/// background detail on a card whose decision lives under the rule.
///
/// One clock leads the pair: the time is what a rider weighs, the distance
/// carries its own unit and needs no glyph to be read as a distance. Two icons
/// here turned a caption into a toolbar.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.route});

  final RouteSummary route;

  @override
  Widget build(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);
    final style = ClientTypography.bodySmall(context).copyWith(color: muted);
    final hasDuration = route.duration.isNotEmpty;

    return Row(
      children: [
        if (hasDuration) ...[
          Icon(Icons.schedule_rounded, size: 15, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              route.duration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
        if (hasDuration && route.distance.isNotEmpty)
          const SizedBox(width: ClientSpacing.md),
        if (route.distance.isNotEmpty)
          Flexible(
            child: Text(
              route.distance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
  }
}

/// "Passing through Banha" — why this corridor is in the results when neither
/// of its endpoints is what the rider typed.
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

/// The part of the card a rider decides on, under the rule: can I book this,
/// and who am I booking from.
///
/// The verdict takes the leading edge — first thing read in either script —
/// and the operator anchors the far corner with its mark last, so a column of
/// cards lines up as a column of answers with a column of brands beside it.
class _DecisionRow extends StatelessWidget {
  const _DecisionRow({required this.route});

  final RouteSummary route;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvailabilityPill(status: route.availability.status),
        if (route.officeName.isNotEmpty) ...[
          const SizedBox(width: ClientSpacing.sm),
          // Expanded + end-alignment rather than a [Spacer]: two flexible
          // children would each take half the leftover width and leave a short
          // operator name floating in the middle of the row instead of closing
          // it.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _OperatorMark(
                name: route.officeName,
                logoUrl: route.officeLogoUrl,
                brandKey: route.officeId,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Who runs the corridor: the office's name, then its own mark closing the row.
class _OperatorMark extends StatelessWidget {
  const _OperatorMark({
    required this.name,
    required this.logoUrl,
    this.brandKey,
  });

  final String name;
  final String? logoUrl;

  /// The office id, so its no-logo mark keeps one colour across the app.
  final String? brandKey;

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: ClientTypography.labelLarge(context).copyWith(
              color: ClientColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _OperatorAvatar(logoUrl: logoUrl, size: _size, brandKey: brandKey),
      ],
    );
  }
}

/// The office's picture when it has uploaded one, the design's gradient brand
/// tile when it has not — never a broken-image tile, the same answer
/// [OfficeLogoAvatar] gives on every other screen that draws an operator.
///
/// Deliberately not the office's initials, which the design file fills this
/// tile with: they read as a brand mark only for a Latin acronym, and an
/// Arabic trading name ("شركة الدلتا للنقل") reduces to one disconnected
/// letter that identifies nothing — the design's own mock shows "إيزي واي"
/// collapsing to a bare stroke.
class _OperatorAvatar extends StatelessWidget {
  const _OperatorAvatar({
    required this.logoUrl,
    required this.size,
    this.brandKey,
  });

  final String? logoUrl;
  final double size;
  final String? brandKey;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    final radius = BorderRadius.circular(size * 0.32);
    final fallback = ClientBrandAvatar.glyph(
      icon: Icons.storefront_rounded,
      size: size,
      brandKey: brandKey,
    );

    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: radius,
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
    // The design's three availability tones are a traffic light — green on
    // sale, amber full, grey nothing running — not three shades of brand. On a
    // list of corridors that is the difference between scanning and reading:
    // "bookable" used to wear the same blue as every other chip on the card.
    final (Color ink, Color bg, String label) = switch (status) {
      RouteAvailabilityStatus.bookable => (
        ClientColors.onJourneyGreenFor(context),
        ClientColors.journeyGreenLightFor(context),
        l10n.routes_availabilityBookable,
      ),
      RouteAvailabilityStatus.soldOut => (
        ClientColors.onJourneyAmberFor(context),
        ClientColors.journeyAmberLightFor(context),
        l10n.routes_availabilitySoldOut,
      ),
      RouteAvailabilityStatus.none || RouteAvailabilityStatus.unknown => (
        ClientColors.onJourneySlateFor(context),
        ClientColors.journeySlateLightFor(context),
        l10n.routes_availabilityNone,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelMedium(
          context,
        ).copyWith(color: ink, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          if (departure.isNotEmpty)
            Expanded(
              child: Text(
                departure,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
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
              style: ClientTypography.bodySmall(context).copyWith(
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

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_journey_timeline.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_section.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Every station this trip calls at, in running order, with the rider's own two
/// marked out of the line.
///
/// The hero states a journey as two place names, which is the ticket's answer
/// and not the road's: a rider who boards mid-corridor wants to know what the
/// bus does before it reaches them and where it goes after they get off. That
/// is the whole corridor, drawn on the shared [ClientJourneyTimeline] so the
/// list here and the live one on the tracking screen are the same object at two
/// states rather than two lists to learn.
///
/// Stops outside the rider's own leg are faded, never hidden — they belong to
/// other passengers' journeys, and they are *why* the trip takes as long as it
/// does.
class TripStationsCard extends StatefulWidget {
  const TripStationsCard({super.key, required this.trip});

  final TripData trip;

  @override
  State<TripStationsCard> createState() => _TripStationsCardState();
}

class _TripStationsCardState extends State<TripStationsCard> {
  /// How many stops a corridor may have before the list collapses to the
  /// rider's own leg. Six rows is about as much timeline as fits under the
  /// cards above it without turning Trip Details into a scroll.
  static const int _collapseAbove = 6;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final stops = trip.stops;
    if (stops.isEmpty) return const SizedBox.shrink();

    final visible = _visibleIndices(trip);
    final collapsible = visible.length < stops.length;

    return TripDetailSection(
      title: context.l10n.tracking_stopsTitle,
      subtitle: context.l10n.trips_stationsSubtitle,
      icon: Icons.alt_route_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trip.boardingStop != null && trip.dropoffStop != null) ...[
            _RiderLegPanel(trip: trip),
            const SizedBox(height: 18),
          ],
          ClientJourneyTimeline(
            dense: true,
            stops: [for (final index in visible) _stop(context, trip, index)],
          ),
          if (collapsible || _expanded) ...[
            const SizedBox(height: 6),
            _ExpandToggle(
              expanded: _expanded,
              total: stops.length,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          ],
          if (_anyTimed(trip)) ...[
            const SizedBox(height: 10),
            // Said once, at the bottom, rather than beside every number: these
            // are the published times and the road decides.
            Text(
              context.l10n.tracking_etaMayChange,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
          ],
        ],
      ),
    );
  }

  ClientJourneyStop _stop(BuildContext context, TripData trip, int index) {
    final stop = trip.stops[index];
    final onLeg = trip.isOnRiderLeg(index);

    return ClientJourneyStop(
      name: stop.name.isEmpty
          ? context.l10n.trips_routePointUnknown
          : stop.name,
      trailing: _clock(context, trip, index),
      badge: stop.isBoarding
          ? context.l10n.tracking_yourStopBadge
          : stop.isDropoff
          ? context.l10n.tracking_yourDropoffBadge
          : null,
      // The two terminals carry the corridor's identity and the rider's two
      // stops carry their journey; everything else is a place the bus passes.
      emphasised: stop.isMine || index == 0 || index == trip.stops.length - 1,
      dimmed: !onLeg,
    );
  }

  /// A stop's clock time: the corridor's first stop is the departure itself,
  /// every other one is that departure plus the stop's offset.
  String _clock(BuildContext context, TripData trip, int index) {
    final stop = trip.stops[index];
    final offset = stop.arrivalOffset.isNotEmpty
        ? stop.arrivalOffset
        : stop.departureOffset;
    return formatStopClock(context, trip.timeLabel, offset);
  }

  bool _anyTimed(TripData trip) => trip.stops.any(
    (stop) => stop.arrivalOffset.isNotEmpty || stop.departureOffset.isNotEmpty,
  );

  /// Which stops to draw.
  ///
  /// A short corridor is drawn whole. A long one collapses to the rider's own
  /// leg with a stop of context either side — the part of the road that is
  /// theirs — and to the first rows when the booking never recorded where they
  /// get on and off.
  List<int> _visibleIndices(TripData trip) {
    final count = trip.stops.length;
    final all = [for (var i = 0; i < count; i++) i];
    if (_expanded || count <= _collapseAbove) return all;

    final from = trip.stops.indexWhere((stop) => stop.isBoarding);
    final to = trip.stops.indexWhere((stop) => stop.isDropoff);
    if (from < 0 || to < 0) return all.take(_collapseAbove).toList();

    final first = (from <= to ? from : to) - 1;
    final last = (from <= to ? to : from) + 1;
    return all
        .where((index) => index >= first && index <= last)
        .toList(growable: false);
  }
}

/// Where this rider gets on and off, lifted out of the line into a panel of
/// their own — the two rows of the corridor that are actually about them.
class _RiderLegPanel extends StatelessWidget {
  const _RiderLegPanel({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final boarding = trip.boardingStop!;
    final dropoff = trip.dropoffStop!;
    final color = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _LegEnd(
              icon: Icons.arrow_upward_rounded,
              label: context.l10n.tracking_boardAt,
              place: boarding.name,
              time: formatStopClock(
                context,
                trip.timeLabel,
                boarding.departureOffset.isNotEmpty
                    ? boarding.departureOffset
                    : boarding.arrivalOffset,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: color.withAlpha(45),
          ),
          Expanded(
            child: _LegEnd(
              icon: Icons.arrow_downward_rounded,
              label: context.l10n.tracking_alightAt,
              place: dropoff.name,
              time: formatStopClock(
                context,
                trip.timeLabel,
                dropoff.arrivalOffset.isNotEmpty
                    ? dropoff.arrivalOffset
                    : dropoff.departureOffset,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegEnd extends StatelessWidget {
  const _LegEnd({
    required this.icon,
    required this.label,
    required this.place,
    required this.time,
  });

  final IconData icon;
  final String label;
  final String place;
  final String time;

  @override
  Widget build(BuildContext context) {
    final color = ClientColors.primaryFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          place.isEmpty ? context.l10n.trips_routePointUnknown : place,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w800,
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Show all 9 stops" / "Show fewer" — the corridor is never truncated
/// silently, so the row that hides stops is also the row that says how many.
class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({
    required this.expanded,
    required this.total,
    required this.onTap,
  });

  final bool expanded;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          size: 18,
        ),
        label: Text(
          expanded
              ? context.l10n.trips_stationsShowLess
              : context.l10n.trips_stationsShowAll(total),
        ),
        style: TextButton.styleFrom(
          foregroundColor: ClientColors.primaryFor(context),
          textStyle: ClientTypography.labelLarge(context),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
        ),
      ),
    );
  }
}

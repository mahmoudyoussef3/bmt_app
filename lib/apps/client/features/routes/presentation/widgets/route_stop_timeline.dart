import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_journey_timeline.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/route_stop.dart';

/// The route's full corridor as an ordered, connected list of stops.
///
/// Draws through the shared [ClientJourneyTimeline] so a corridor here and the
/// live spine on the tracking screen are the same object at two states, rather
/// than two timelines a rider has to learn separately.
class RouteStopTimeline extends StatelessWidget {
  const RouteStopTimeline({super.key, required this.stops});

  final List<RouteStop> stops;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClientJourneyTimeline(
      dense: true,
      stops: [
        for (var i = 0; i < stops.length; i++)
          ClientJourneyStop(
            name: stops[i].name,
            // The two terminals carry the corridor's identity, so they stay
            // bold even though no vehicle has reached either of them.
            emphasised: i == 0 || i == stops.length - 1,
            subtitle: _joinOrNull([
              if (stops[i].area.isNotEmpty) stops[i].area,
              if (stops[i].estimatedArrivalTime.isNotEmpty)
                stops[i].estimatedArrivalTime,
              if (!stops[i].pickupAllowed)
                l10n.routes_dropoffOnly
              else if (!stops[i].dropoffAllowed)
                l10n.routes_pickupOnly,
            ]),
          ),
      ],
    );
  }

  String? _joinOrNull(List<String> parts) =>
      parts.isEmpty ? null : parts.join(' · ');
}

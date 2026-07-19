import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_journey_nodes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_journey_stop.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The pickup → drop-off rail on the trip hero.
///
/// Replaces the single "A → B" headline, which wrapped a long route across
/// three lines and buried the arrow mid-sentence. Two anchored stops read at a
/// glance and give the hero a stable height regardless of place-name length.
class HeroJourney extends StatelessWidget {
  const HeroJourney({
    super.key,
    required this.pickup,
    required this.destination,
    required this.departureLabel,
  });

  final String pickup;
  final String destination;
  final String departureLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroJourneyStop(
          node: const HeroOriginNode(),
          label: context.l10n.common_pickup.toUpperCase(),
          place: pickup,
          trailing: departureLabel,
        ),
        const _JourneyConnector(),
        HeroJourneyStop(
          node: const HeroDestinationNode(),
          label: context.l10n.common_dropOff.toUpperCase(),
          place: destination,
        ),
      ],
    );
  }
}

/// The vertical rail joining the two stops.
class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 9, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(70),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

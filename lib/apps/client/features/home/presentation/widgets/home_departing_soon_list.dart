import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_departure_card.dart';

/// Horizontal carousel of trips leaving soon, with the next card peeking on
/// the edge to invite scrolling.
class HomeDepartingSoonList extends StatelessWidget {
  const HomeDepartingSoonList({
    super.key,
    required this.trips,
    required this.onSelect,
  });

  final List<NearbyTripData> trips;
  final ValueChanged<NearbyTripData> onSelect;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 720 ? 310.0 : (width - 72).clamp(260.0, 330.0);

    return SizedBox(
      height: HomeDepartureCard.listHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: trips.length,
        separatorBuilder: (_, _) => const SizedBox(width: ClientSpacing.sm),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return HomeDepartureCard(
            trip: trip,
            width: cardWidth,
            onTap: () => onSelect(trip),
          );
        },
      ),
    );
  }
}

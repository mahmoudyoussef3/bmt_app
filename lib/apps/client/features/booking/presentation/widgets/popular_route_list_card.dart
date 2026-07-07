import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_card_cta_row.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_card_endpoint_line.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_card_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_fact_chip.dart';

/// A premium route-discovery result card: surfaces origin, destination,
/// distance, duration, trip availability, and starting price at a glance.
class PopularRouteListCard extends StatelessWidget {
  const PopularRouteListCard({
    super.key,
    required this.route,
    required this.onTap,
  });

  final PopularRouteListData route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasTrips = route.dailyTrips > 0;
    final pricePending =
        route.startingPrice.trim().toLowerCase() == 'price pending';

    return ClientCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteCardHeader(
            routeName: route.routeName,
            hasTrips: hasTrips,
            dailyTrips: route.dailyTrips,
            startingPrice: route.startingPrice,
            pricePending: pricePending,
          ),
          const SizedBox(height: 16),
          RouteEndpointLine(
            pickup: route.pickup,
            destination: route.destination,
            active: hasTrips,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RouteFactChip(
                icon: Icons.straighten_rounded,
                label: route.distance,
              ),
              RouteFactChip(
                icon: Icons.schedule_rounded,
                label: route.averageDuration,
              ),
              RouteFactChip(
                icon: Icons.directions_bus_rounded,
                label: hasTrips ? 'Seats available' : 'Check later',
              ),
            ],
          ),
          const Spacer(),
          RouteCardCtaRow(hasTrips: hasTrips),
        ],
      ),
    );
  }
}

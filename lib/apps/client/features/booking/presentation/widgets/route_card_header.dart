import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_card_chips.dart';

/// The top row of [PopularRouteListCard]: route icon, name, trip-availability
/// badge, and starting price.
class RouteCardHeader extends StatelessWidget {
  const RouteCardHeader({
    super.key,
    required this.routeName,
    required this.hasTrips,
    required this.dailyTrips,
    required this.startingPrice,
    required this.pricePending,
  });

  final String routeName;
  final bool hasTrips;
  final int dailyTrips;
  final String startingPrice;
  final bool pricePending;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasTrips
                ? ClientColors.primaryContainerFor(context)
                : ClientColors.surfaceMutedFor(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.route_rounded,
            color: hasTrips
                ? ClientColors.primaryFor(context)
                : ClientColors.textTertiaryFor(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(context),
              ),
              const SizedBox(height: 6),
              RouteAvailabilityBadge(
                label: hasTrips
                    ? '$dailyTrips ${dailyTrips == 1 ? 'trip' : 'trips'} today'
                    : 'No trips today',
                active: hasTrips,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        RoutePriceBlock(price: startingPrice, pending: pricePending),
      ],
    );
  }
}

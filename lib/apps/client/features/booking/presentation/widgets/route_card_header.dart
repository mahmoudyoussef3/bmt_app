import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/transport_office.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_office_chip.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_card_chips.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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
    this.office = TransportOffice.unknown,
  });

  final String routeName;
  final bool hasTrips;
  final int dailyTrips;
  final String startingPrice;
  final bool pricePending;
  final TransportOffice office;

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
              const SizedBox(height: 4),
              // Which office runs this corridor — without it, two providers'
              // departures read as one operator's timetable.
              RouteOfficeChip(office: office),
              const SizedBox(height: 6),
              RouteAvailabilityBadge(
                label: hasTrips
                    ? context.l10n.booking_tripsCountToday(dailyTrips)
                    : context.l10n.booking_noTripsToday,
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

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Small chips/badges used inside [PopularRouteListCard]: trip-availability
/// badge, starting-price block, and route fact chips (distance/duration/seats).
class RouteAvailabilityBadge extends StatelessWidget {
  const RouteAvailabilityBadge({
    super.key,
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? ClientColors.journeyGreenLight
        : ClientColors.journeySlateLight;
    final foreground = active
        ? ClientColors.onJourneyGreen
        : ClientColors.onJourneySlate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.info_rounded,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: foreground, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class RoutePriceBlock extends StatelessWidget {
  const RoutePriceBlock({
    super.key,
    required this.price,
    required this.pending,
  });

  final String price;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            pending ? 'Price' : 'From',
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            price,
            maxLines: pending ? 2 : 1,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: pending
                ? ClientTypography.labelLarge(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  )
                : ClientTypography.priceMedium(
                    context,
                  ).copyWith(fontSize: 18, height: 1.05),
          ),
        ],
      ),
    );
  }
}

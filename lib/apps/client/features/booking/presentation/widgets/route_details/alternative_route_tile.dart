import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_type_classifier.dart';

/// A single alternative-route row inside [RouteAlternativesSection], tagged
/// direct/multi-stop via the route-type classifier.
class AlternativeRouteTile extends StatelessWidget {
  const AlternativeRouteTile({
    super.key,
    required this.route,
    required this.onTap,
  });

  final RouteOptionData route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = classifyRouteType(route);

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ClientColors.borderFor(context)),
          color: ClientColors.surfaceFor(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.routeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodyMedium(
                            context,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RouteTypeBadge(type: type),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${route.duration} · ${route.startingPrice}',
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ClientColors.textTertiaryFor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteTypeBadge extends StatelessWidget {
  const _RouteTypeBadge({required this.type});

  final RouteType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        routeTypeLabel(type),
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

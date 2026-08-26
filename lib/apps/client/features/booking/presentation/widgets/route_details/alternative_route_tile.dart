import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_type_classifier.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_fact_line.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// A single alternative-line row inside [RouteAlternativesSection], tagged
/// direct/multi-stop via the route-type classifier.
///
/// It states duration and station count, not a fare: switching lines here only
/// changes *which line* is being reviewed, and the price of a seat on it is
/// still a function of stops the rider has not chosen.
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
    final l10n = context.l10n;
    final stops = route.points.length;

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          border: Border.all(color: ClientColors.borderFor(context)),
          color: ClientColors.surfaceSubtleFor(context),
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
                        child: RouteDirectionText(
                          origin: route.pickup,
                          destination: route.destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodyMedium(
                            context,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RouteTypeBadge(type: classifyRouteType(route)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RouteFactLine(
                    facts: [
                      route.duration,
                      route.distance,
                      if (stops > 0)
                        stops == 1
                            ? l10n.booking_oneStop
                            : l10n.booking_stopsCountLabel(stops),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            DirectionalIcon(
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
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        routeTypeLabel(context, type),
        style: ClientTypography.labelSmall(context).copyWith(
          color: ClientColors.textSecondaryFor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

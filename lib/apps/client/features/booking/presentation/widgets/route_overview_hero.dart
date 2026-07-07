import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';

/// [RouteOverviewScreen]'s hero: route origin/destination endpoints plus a
/// compact fact row (duration, distance, seats).
class RouteOverviewHero extends StatelessWidget {
  const RouteOverviewHero({
    super.key,
    required this.route,
    required this.stops,
  });

  final RouteOptionData route;
  final List<RoutePointData> stops;

  @override
  Widget build(BuildContext context) {
    final start = stops.isEmpty ? route.pickup : stops.first.name;
    final end = stops.isEmpty ? route.destination : stops.last.name;

    return BookingSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROUTE OVERVIEW',
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.primary, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RouteEnd(label: 'FROM', value: start),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ClientColors.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _RouteEnd(label: 'TO', value: end, alignEnd: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteEnd extends StatelessWidget {
  const _RouteEnd({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

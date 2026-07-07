import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_overview_metric.dart';

/// Route Details' header card: name, distance/duration, and a compact metric
/// row (departure, destination, distance, duration).
class RouteOverviewHeader extends StatelessWidget {
  const RouteOverviewHeader({super.key, required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClientCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(isDark ? 30 : 25),
                  borderRadius: BorderRadius.circular(ClientRadius.lg),
                ),
                child: Icon(Icons.route_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.routeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.distance} • ${route.duration}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(160),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RouteOverviewMetric(
                icon: Icons.trip_origin_rounded,
                label: 'Departure',
                value: route.pickup,
              ),
              RouteOverviewMetric(
                icon: Icons.flag_rounded,
                label: 'Destination',
                value: route.destination,
              ),
              RouteOverviewMetric(
                icon: Icons.straighten_rounded,
                label: 'Distance',
                value: route.distance,
              ),
              RouteOverviewMetric(
                icon: Icons.schedule_rounded,
                label: 'Duration',
                value: route.duration,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

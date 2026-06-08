import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_route.dart';

class RouteTimeline extends StatelessWidget {
  final OperationRoute route;

  const RouteTimeline({required this.route, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معاينة الرحلة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xSmall),
          Text('${route.startCity} ← ${route.endCity} • ${route.distance}'),
          const SizedBox(height: AppSpacing.large),
          ...route.stations.indexed.map((entry) {
            final (index, station) = entry;
            final last = index == route.stations.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primaryContainer,
                      child: Text('${index + 1}'),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 48,
                        color: scheme.outline.withAlpha(120),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text('${station.area} • ${station.arrivalOffset}'),
                        if (station.notes.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(station.notes),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

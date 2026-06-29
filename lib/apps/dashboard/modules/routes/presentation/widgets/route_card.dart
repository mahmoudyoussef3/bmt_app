import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_route.dart';
import 'route_status_badge.dart';

class RouteCard extends StatelessWidget {
  final OperationRoute route;
  final bool selected;
  final VoidCallback onTap;

  const RouteCard({
    required this.route,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withAlpha(0),
            width: selected ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  RouteStatusBadge(status: route.status),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _RouteFact(
                label: 'عدد المحطات',
                value: '${route.stations.length}',
              ),
              _RouteFact(label: 'مدة الرحلة', value: route.duration),
              _RouteFact(label: 'المسافة', value: route.distance),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteFact extends StatelessWidget {
  final String label;
  final String value;

  const _RouteFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

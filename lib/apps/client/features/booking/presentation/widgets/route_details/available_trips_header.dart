import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_filters_button.dart';

/// Title, subtitle, and the filters trigger for [RouteAvailableTripsSection].
class AvailableTripsHeader extends StatelessWidget {
  const AvailableTripsHeader({
    super.key,
    required this.showFilters,
    required this.activeFilters,
    required this.onOpenFilters,
  });

  final bool showFilters;
  final int activeFilters;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available trips',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the departure that works best for you.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        if (showFilters)
          RouteFiltersButton(activeCount: activeFilters, onTap: onOpenFilters),
      ],
    );
  }
}

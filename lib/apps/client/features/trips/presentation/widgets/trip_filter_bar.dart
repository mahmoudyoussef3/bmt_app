import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

class TripFilterBar extends StatelessWidget {
  const TripFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  final TripFilter selected;
  final ValueChanged<TripFilter> onSelected;
  final Map<TripFilter, int>? counts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TripFilter.values.map((filter) {
            final active = selected == filter;
            final count = counts?[filter] ?? 0;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(
                  count > 0 ? '${filter.label} ($count)' : filter.label,
                ),
                selected: active,
                onSelected: (_) => onSelected(filter),
                selectedColor: scheme.primary.withAlpha(24),
                side: BorderSide(
                  color: active ? scheme.primary : scheme.outline.withAlpha(90),
                ),
                labelStyle: TextStyle(
                  color: active ? scheme.primary : scheme.onSurface,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

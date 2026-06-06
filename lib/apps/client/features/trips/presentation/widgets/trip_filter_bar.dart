import 'package:flutter/material.dart';
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: TripFilter.values.map((filter) {
          final active = selected == filter;
          final count = counts?[filter] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                count > 0 ? '${filter.label} ($count)' : filter.label,
              ),
              selected: active,
              onSelected: (_) => onSelected(filter),
              selectedColor: scheme.primary.withAlpha(55),
              checkmarkColor: scheme.primary,
              side: BorderSide(
                color: active ? scheme.primary : scheme.outline.withAlpha(120),
              ),
              labelStyle: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

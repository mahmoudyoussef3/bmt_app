import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

String _filterLabel(BuildContext context, TripFilter filter) {
  return switch (filter) {
    TripFilter.upcoming => context.l10n.trips_filterUpcoming,
    TripFilter.active => context.l10n.trips_filterActive,
    TripFilter.completed => context.l10n.trips_filterCompleted,
    TripFilter.cancelled => context.l10n.trips_filterCancelled,
  };
}

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
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in TripFilter.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _FilterPill(
                  label: _filterLabel(context, filter),
                  count: counts?[filter] ?? 0,
                  active: selected == filter,
                  onTap: () => onSelected(filter),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single filter as a tappable pill. No checkmark — selection reads from the
/// filled tint, the primary border, and the bolder label, so the tab never
/// crowds a tick glyph against its text.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = active ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? scheme.primary.withAlpha(28)
                : scheme.surfaceContainerHighest.withAlpha(90),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? scheme.primary : scheme.outline.withAlpha(70),
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 7),
                _CountBadge(count: count, active: active),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.active});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary
            : scheme.onSurfaceVariant.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          height: 1.1,
        ),
      ),
    );
  }
}

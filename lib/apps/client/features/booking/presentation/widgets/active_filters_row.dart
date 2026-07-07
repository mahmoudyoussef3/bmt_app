import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';

/// Lists every active filter as an individually removable chip, plus a
/// single reset-all action (spec FR-004). Renders nothing when no filter is
/// active.
class ActiveFiltersRow extends StatelessWidget {
  const ActiveFiltersRow({
    super.key,
    required this.criteria,
    required this.onChanged,
    required this.onResetAll,
  });

  final RouteFilterCriteria criteria;
  final ValueChanged<RouteFilterCriteria> onChanged;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    if (criteria.activeCount == 0) return const SizedBox.shrink();

    final chips = <Widget>[
      if (criteria.priceRange != null)
        _Chip(
          label:
              '\$${criteria.priceRange!.start.round()}-\$${criteria.priceRange!.end.round()}',
          onRemoved: () => onChanged(criteria.copyWith(clearPriceRange: true)),
        ),
      if (criteria.durationRange != null)
        _Chip(
          label:
              '${criteria.durationRange!.start.round()}-${criteria.durationRange!.end.round()}m',
          onRemoved: () =>
              onChanged(criteria.copyWith(clearDurationRange: true)),
        ),
      if (criteria.pickup != null)
        _Chip(
          label: criteria.pickup!,
          onRemoved: () => onChanged(criteria.copyWith(clearPickup: true)),
        ),
      if (criteria.destination != null)
        _Chip(
          label: criteria.destination!,
          onRemoved: () => onChanged(criteria.copyWith(clearDestination: true)),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: ClientSpacing.sm),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...chips,
          ActionChip(
            label: Text(
              'Reset all',
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            onPressed: onResetAll,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      backgroundColor: ClientColors.primaryFor(context).withAlpha(18),
      labelStyle: ClientTypography.labelMedium(context).copyWith(
        color: ClientColors.primaryFor(context),
        fontWeight: FontWeight.w800,
      ),
      deleteIcon: Icon(
        Icons.close_rounded,
        size: 16,
        color: ClientColors.primaryFor(context),
      ),
      onDeleted: onRemoved,
      side: BorderSide.none,
    );
  }
}

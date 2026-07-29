import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_filter_count_badge.dart';

/// A single filter as a tappable pill. No checkmark — selection reads from the
/// filled tint, the primary border, and the bolder label, so the tab never
/// crowds a tick glyph against its text.
class TripFilterPill extends StatelessWidget {
  const TripFilterPill({
    super.key,
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
    final foreground = active
        ? ClientColors.primaryFor(context)
        : ClientColors.textSecondaryFor(context);

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
                ? ClientColors.primaryFor(context).withAlpha(28)
                : ClientColors.surfaceMutedFor(context).withAlpha(90),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? ClientColors.primaryFor(context)
                  : ClientColors.borderFor(context).withAlpha(70),
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: ClientTypography.labelLarge(context).copyWith(
                  color: foreground,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 7),
                TripFilterCountBadge(count: count, active: active),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

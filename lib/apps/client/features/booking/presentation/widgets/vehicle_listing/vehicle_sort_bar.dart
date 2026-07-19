import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Horizontal sort selector for the vehicle listing.
class VehicleSortBar extends StatelessWidget {
  const VehicleSortBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final VehicleSortOption selected;
  final ValueChanged<VehicleSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (
        VehicleSortOption.recommended,
        l10n.booking_sortEarliest,
        Icons.schedule_rounded,
      ),
      (
        VehicleSortOption.priceLow,
        l10n.booking_sortLowestPrice,
        Icons.payments_rounded,
      ),
      (
        VehicleSortOption.seats,
        l10n.booking_sortMostSeats,
        Icons.event_seat_rounded,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((entry) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: VehicleSortChip(
              icon: entry.$3,
              label: entry.$2,
              active: selected == entry.$1,
              onTap: () => onSelected(entry.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class VehicleSortChip extends StatelessWidget {
  const VehicleSortChip({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? ClientColors.primaryContainerFor(context)
              : ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? ClientColors.primaryMuted
                : ClientColors.borderFor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? ClientColors.primaryFor(context)
                  : ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: ClientTypography.bodySmall(context).copyWith(
                color: active
                    ? ClientColors.primaryFor(context)
                    : ClientColors.textPrimaryFor(context),
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

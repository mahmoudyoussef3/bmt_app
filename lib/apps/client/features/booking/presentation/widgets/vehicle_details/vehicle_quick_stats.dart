import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_detail_atoms.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Price / seats / departure summary row on the vehicle details screen.
class VehicleQuickStats extends StatelessWidget {
  const VehicleQuickStats({super.key, required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickStat(
              icon: Icons.payments_rounded,
              label: context.l10n.booking_tripPrice,
              value: vehicle.price,
            ),
          ),
          const VehicleStatDivider(),
          Expanded(
            child: _QuickStat(
              icon: Icons.event_seat_rounded,
              label: context.l10n.booking_availableSeats,
              value: '${vehicle.availableSeats}',
            ),
          ),
          const VehicleStatDivider(),
          Expanded(
            child: _QuickStat(
              icon: Icons.schedule_rounded,
              label: context.l10n.booking_departure,
              value: vehicle.departureTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: ClientColors.primary, size: 21),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}

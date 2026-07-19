import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_detail_atoms.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Comfort and amenities card (air conditioning, seat type).
class VehicleComfortCard extends StatelessWidget {
  const VehicleComfortCard({super.key, required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          _ComfortTile(
            icon: Icons.ac_unit_rounded,
            label: context.l10n.booking_ac,
            value: vehicle.hasAirConditioning
                ? context.l10n.booking_available
                : context.l10n.booking_unavailable,
            positive: vehicle.hasAirConditioning,
          ),
          _ComfortTile(
            icon: Icons.chair_rounded,
            label: context.l10n.booking_seatType,
            value: vehicle.seatType,
            positive: true,
          ),
        ],
      ),
    );
  }
}

class _ComfortTile extends StatelessWidget {
  const _ComfortTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive
        ? ClientColors.journeyCyan
        : ClientColors.textTertiaryFor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          VehicleSoftIcon(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            positive ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: color,
            size: 21,
          ),
        ],
      ),
    );
  }
}

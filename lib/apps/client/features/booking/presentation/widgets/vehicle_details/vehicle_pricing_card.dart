import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_detail_atoms.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Price and seat-availability card.
class VehiclePricingCard extends StatelessWidget {
  const VehiclePricingCard({super.key, required this.vehicle});

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
      child: Row(
        children: [
          Expanded(
            child: _PriceSeatColumn(
              label: context.l10n.booking_tripPrice,
              value: vehicle.price,
              icon: Icons.payments_rounded,
              color: ClientColors.primary,
            ),
          ),
          const VehicleStatDivider(),
          Expanded(
            child: _PriceSeatColumn(
              label: context.l10n.booking_availableSeats,
              value:
                  '${vehicle.availableSeats} ${context.l10n.booking_remaining}',
              icon: Icons.event_seat_rounded,
              color: ClientColors.journeyCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSeatColumn extends StatelessWidget {
  const _PriceSeatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VehicleSoftIcon(icon: icon, color: color, size: 42),
        const SizedBox(height: 10),
        Text(
          label,
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w700,
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
      ],
    );
  }
}

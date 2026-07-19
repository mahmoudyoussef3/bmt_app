import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_details/vehicle_detail_atoms.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Compact card echoing the searched route on the vehicle details screen.
class VehicleRouteSummaryCard extends StatelessWidget {
  const VehicleRouteSummaryCard({super.key, required this.summary});

  final String summary;

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
          const VehicleSoftIcon(
            icon: Icons.route_rounded,
            color: ClientColors.primary,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.booking_routeSummary,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

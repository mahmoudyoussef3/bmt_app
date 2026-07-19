import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Driver summary card (avatar, name, certified badge).
class VehicleDriverCard extends StatelessWidget {
  const VehicleDriverCard({super.key, required this.vehicle});

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
          CircleAvatar(
            radius: 30,
            backgroundColor: ClientColors.primaryLight,
            child: Text(
              vehicle.driverInitials,
              style: ClientTypography.headingSmall(
                context,
              ).copyWith(color: ClientColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              vehicle.driverName,
              style: ClientTypography.headingSmall(
                context,
              ).copyWith(color: ClientColors.textPrimaryFor(context)),
            ),
          ),
          ClientStatusBadge(
            status: ClientJourneyStatus.active,
            label: context.l10n.booking_certified,
          ),
        ],
      ),
    );
  }
}

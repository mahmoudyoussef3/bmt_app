import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Sticky price + "select seat" CTA at the bottom of the vehicle details.
class VehicleBottomBar extends StatelessWidget {
  const VehicleBottomBar({super.key, required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          border: Border(
            top: BorderSide(color: ClientColors.borderFor(context)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(16),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.price,
                    style: ClientTypography.priceMedium(
                      context,
                    ).copyWith(color: ClientColors.textPrimaryFor(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.booking_seatsAvailableCount(
                      vehicle.availableSeats,
                    ),
                    style: ClientTypography.bodySmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ClientButton(
                label: context.l10n.booking_selectSeat,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/seat-selection',
                  arguments: {'tripId': vehicle.id},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

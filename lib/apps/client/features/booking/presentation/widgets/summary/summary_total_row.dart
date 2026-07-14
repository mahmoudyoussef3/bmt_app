import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';

/// The total, pinned above the call to action. The old summary buried it two
/// scrolls below "Proceed to Payment", so riders committed without ever seeing
/// what they were about to pay.
class SummaryTotalRow extends StatelessWidget {
  const SummaryTotalRow({super.key, required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final rides = session.selectedPackage?.rideCount ?? 1;
    final plan = session.selectedPackage?.displayName ?? '';
    final ridesLabel = rides == 1 ? '1 ride' : '$rides rides';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total due',
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
              const SizedBox(height: 2),
              Text(
                plan.isEmpty ? ridesLabel : '$plan · $ridesLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'EGP ${session.totalPrice.toStringAsFixed(0)}',
          style: ClientTypography.priceMedium(
            context,
          ).copyWith(color: ClientColors.primaryFor(context)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_fact_cell.dart';

/// Seat and fare as fixed cells, then the status explanation folded into the
/// same panel instead of a second bordered box — one surface for "what this
/// booking is" rather than two competing for the rider's attention. Mirrors
/// the departure board's facts panel cell for cell.
class HomeBookingStatusPanel extends StatelessWidget {
  const HomeBookingStatusPanel({super.key, required this.booking});

  final HomeBookingData booking;

  @override
  Widget build(BuildContext context) {
    final border = ClientColors.borderFor(context);
    final l10n = context.l10n;
    final accent = booking.status.accent;

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: HomeFactCell(
                    icon: Icons.event_seat_rounded,
                    caption: l10n.common_seats,
                    value: booking.seatLabel.isEmpty
                        ? l10n.common_notSet
                        : booking.seatLabel,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: border),
                Expanded(
                  child: HomeFactCell(
                    icon: Icons.payments_rounded,
                    caption: l10n.home_amountPaid,
                    value: booking.fare.isEmpty
                        ? l10n.common_notSet
                        : booking.fare,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: border),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClientSpacing.sm,
              vertical: ClientSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(booking.status.icon, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.status.explanationFor(l10n),
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(color: accent, fontWeight: FontWeight.w700),
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

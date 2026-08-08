import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';

/// The ticket's departure band, identical in spirit to the departure board's
/// header: icon on the lead edge, schedule as the headline, status badge on
/// the trailing edge. The booking reference moves out of the headline
/// position it used to hold — a rider scans for *when*, not for an operator
/// reference number — and becomes a small caption under the time instead.
class HomeBookingCardHeader extends StatelessWidget {
  const HomeBookingCardHeader({super.key, required this.booking});

  final HomeBookingData booking;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = booking.status;
    final accent = status.accent;

    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 30 : 16),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withAlpha(36),
              borderRadius: BorderRadius.circular(ClientRadius.sm),
            ),
            child: Icon(status.icon, color: accent, size: 22),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(child: _Schedule(booking: booking)),
          const SizedBox(width: ClientSpacing.xs),
          ClientStatusBadge(
            status: status.badge,
            label: status.labelFor(context.l10n),
            showDot: status.isPulsing,
          ),
        ],
      ),
    );
  }
}

class _Schedule extends StatelessWidget {
  const _Schedule({required this.booking});

  final HomeBookingData booking;

  @override
  Widget build(BuildContext context) {
    final time = formatTripTime(context, booking.departureTime);
    final day = formatTripDay(context, booking.tripDate);
    final reference = booking.bookingNumber.isEmpty
        ? context.l10n.home_yourBookingFallback
        : '#${booking.bookingNumber}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                time.isEmpty ? context.l10n.home_departureToBeSet : time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (day.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '· $day',
                style: ClientTypography.labelMedium(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          reference,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}

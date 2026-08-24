import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/pulse_dot.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// The rider's soonest trackable seat, drawn as a hero card directly under
/// the search — a rider who already holds a live seat is shown it before
/// anything else Home has to offer.
///
/// Only for a [HomeBookingStatus.isTrackable] booking (confirmed or on
/// board): there is a bus to point at. An under-review booking has no
/// position to show yet and keeps the plainer [HomeBookingCard] treatment.
class HomeLiveTripBanner extends StatelessWidget {
  const HomeLiveTripBanner({
    super.key,
    required this.booking,
    required this.onTrack,
  });

  final HomeBookingData booking;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = booking.status;

    return PressableScale(
      onTap: onTrack,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(ClientSpacing.lg),
        decoration: BoxDecoration(
          gradient: ClientColors.heroGradientFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          boxShadow: ClientElevation.md(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _LiveBadge(pulsing: status.isPulsing),
                const Spacer(),
                Icon(
                  Icons.near_me_rounded,
                  color: Colors.white.withAlpha(220),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.home_ongoingTrip,
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: ClientSpacing.md),
            RouteDirectionText(
              origin: booking.pickup,
              destination: booking.destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.headingLarge(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              status.explanationFor(l10n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: Colors.white.withAlpha(210)),
            ),
            const SizedBox(height: ClientSpacing.md),
            Divider(color: Colors.white.withAlpha(50), height: 1),
            const SizedBox(height: ClientSpacing.sm),
            Row(
              children: [
                InkWell(
                  onTap: onTrack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.home_trackTrip,
                        style: ClientTypography.labelMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (booking.seatLabel.isNotEmpty)
                  Text(
                    l10n.home_seatNumber(booking.seatLabel),
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(color: Colors.white.withAlpha(220)),
                  )
                else if (booking.departureTime.isNotEmpty)
                  Text(
                    formatTripTime(context, booking.departureTime),
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(color: Colors.white.withAlpha(220)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.pulsing});

  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pulsing
              ? const PulseDot(color: Colors.white, size: 7)
              : Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: 6),
          Text(
            context.l10n.home_liveLocationBadge,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

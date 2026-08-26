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
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// The rider's soonest trackable seat, drawn as a hero card directly under
/// the search — a rider who already holds a live seat is shown it before
/// anything else Home has to offer.
///
/// Only for a [HomeBookingStatus.isTrackable] booking (confirmed or on
/// board): there is a bus to point at. An under-review booking has no
/// position to show yet and keeps the plainer [HomeBookingCard] treatment.
///
/// It reads top to bottom as one answer: tracking is live, this is where you
/// are going, this is what to do about it now, and here is the seat and the
/// button. The route sets in two lines rather than one — a rider whose
/// destination is elided cannot use the card at all — and it sits a step
/// below the hero headline in the type scale, so the page keeps one largest
/// voice instead of two shouting over each other.
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
    final departure = booking.departureTime.isEmpty
        ? ''
        : formatTripTime(context, booking.departureTime);

    return PressableScale(
      onTap: onTrack,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(ClientSpacing.lg),
        decoration: BoxDecoration(
          // The design gives the live-trip card the brand gradient
          // (`--primary` → `--primary-2`), not the hero's navy: stacked
          // directly under the header, two identical gradients read as one
          // long block instead of a card sitting on a page.
          //
          // Deliberately the fixed light-palette ramp in both themes rather
          // than `primaryGradientFor`. Everything drawn on this card is white
          // — the glass chips, the divider, the live badge, and a white pill
          // whose ink is the on-white brand blue — and the dark theme's brand
          // is a light cyan that none of those survive.
          gradient: ClientColors.primaryGradient,
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
                Flexible(
                  child: Text(
                    l10n.home_ongoingTrip,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: Colors.white.withAlpha(215),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClientSpacing.md),
            RouteDirectionText(
              origin: booking.pickup,
              destination: booking.destination,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.headingMedium(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              status.explanationFor(l10n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: Colors.white.withAlpha(205), height: 1.4),
            ),
            const SizedBox(height: ClientSpacing.md),
            Divider(color: Colors.white.withAlpha(50), height: 1),
            const SizedBox(height: ClientSpacing.md),
            Row(
              children: [
                // Takes the whole remainder and aligns its chip to the
                // leading edge, so the button below keeps a fixed home on the
                // trailing side whether or not a seat was assigned.
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: switch ((booking.seatLabel, departure)) {
                      (final seat, _) when seat.isNotEmpty => _GlassChip(
                        icon: Icons.event_seat_rounded,
                        label: l10n.home_seatNumber(seat),
                      ),
                      (_, final time) when time.isNotEmpty => _GlassChip(
                        icon: Icons.schedule_rounded,
                        label: time,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
                const SizedBox(width: ClientSpacing.sm),
                _TrackButton(label: l10n.home_trackTrip, onTap: onTrack),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The card's own call to action.
///
/// A filled pill rather than the bare text link it replaced: on a gradient a
/// white-on-brand button is the one element that reads as pressable at a
/// glance, and it gives the tap a real target instead of the text's own
/// bounds. The arrow is [DirectionalIcon] so it points the way the page
/// reads — the link before it used a left chevron, which Flutter mirrors
/// under RTL into an arrow pointing back the way the rider came.
class _TrackButton extends StatelessWidget {
  const _TrackButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The pill is white in both themes, so its label must be the on-white
    // brand blue in both too. [ClientColors.primaryFor] would hand back the
    // dark theme's lighter accent — tuned to sit on a dark page, and barely
    // 2.4:1 against this button's own white.
    const onBrand = ClientColors.primary;
    final radius = BorderRadius.circular(ClientRadius.pill);

    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: onBrand, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              DirectionalIcon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: onBrand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A fact carried on the gradient — the seat the rider holds, or when the bus
/// leaves when no seat was assigned. Tinted glass rather than a solid fill so
/// it stays a label beside the button and never competes with it.
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        border: Border.all(color: Colors.white.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withAlpha(225)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_card_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_panel.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_journey.dart';

/// A seat the rider already holds, laid out as the same boarding pass the
/// departure board uses: a tinted status band, the journey, a facts panel —
/// so a booked seat and a bookable seat read as one visual language rather
/// than two different card styles competing on the same screen.
///
/// The status is still the headline: a rider who has just paid needs to see
/// that the booking exists and where it stands — not silence.
class HomeBookingCard extends StatelessWidget {
  const HomeBookingCard({
    super.key,
    required this.booking,
    required this.onTrack,
  });

  final HomeBookingData booking;

  /// Opens live tracking. Only offered once the seat is confirmed — there is
  /// no bus to follow while payment is still under review.
  final ValueChanged<HomeBookingData> onTrack;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final trackable = status.isTrackable;

    return PressableScale(
      onTap: trackable ? () => onTrack(booking) : null,
      scale: 0.99,
      child: Container(
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          border: Border.all(color: status.accent.withAlpha(70)),
          boxShadow: ClientElevation.sm(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeBookingCardHeader(booking: booking),
            Padding(
              padding: const EdgeInsets.all(ClientSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeTripJourney(
                    pickup: booking.pickup,
                    destination: booking.destination,
                  ),
                  const SizedBox(height: ClientSpacing.md),
                  HomeBookingStatusPanel(booking: booking),
                ],
              ),
            ),
            if (trackable) ...[
              const TicketTearLine(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClientSpacing.md,
                  ClientSpacing.xs,
                  ClientSpacing.md,
                  ClientSpacing.md,
                ),
                child: ClientButton(
                  label: context.l10n.home_trackYourBus,
                  icon: const Icon(
                    Icons.near_me_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  onPressed: () => onTrack(booking),
                ),
              ),
            ],
          ],
        ), 
      ),
    );
  }
}

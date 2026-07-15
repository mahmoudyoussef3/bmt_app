import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The stub of the ticket: the three facts a rider checks at the door — which
/// seat, which vehicle, and how many rides the fare covers.
class SummaryTicketFacts extends StatelessWidget {
  const SummaryTicketFacts({super.key, required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rides = session.selectedPackage?.rideCount ?? 1;

    return Row(
      children: [
        _Fact(
          label: l10n.payments_stepSeat,
          value: session.selectedSeatLabel ?? '—',
          icon: Icons.event_seat_rounded,
        ),
        _Fact(
          label: l10n.tracking_vehicle,
          value: session.selectedTrip?.vehicleType ?? '—',
          icon: Icons.airport_shuttle_rounded,
        ),
        _Fact(
          label: l10n.booking_ridesLabel,
          value: rides == 1 ? l10n.booking_oneRide : l10n.packages_ridesCount(rides),
          icon: Icons.confirmation_number_rounded,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: ClientColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

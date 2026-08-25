import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_text_direction.dart';

import '../../domain/entities/passenger.dart';

/// The name and the two facts under it.
///
/// The design collapses the old four-line block — seat, pickup, destination,
/// time, each on its own row with its own glyph — into the name plus one
/// supporting line. Seat has moved into the disc beside it, and where the
/// passenger is going matters far less to the captain at the door than where
/// they are getting on, which is the thing being matched against the person
/// standing in front of them.
class PassengerCardDetails extends StatelessWidget {
  const PassengerCardDetails({super.key, required this.passenger});

  final Passenger passenger;

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          passenger.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w700,
            color: CaptainColors.textPrimaryFor(context),
          ),
        ),
        const SizedBox(height: 3),
        _SupportingLine(passenger: passenger),
        if (passenger.pickupTime.isNotEmpty ||
            passenger.destination.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            [
              if (passenger.pickupTime.isNotEmpty) passenger.pickupTime,
              if (passenger.destination.isNotEmpty) passenger.destination,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.labelSmall(context).copyWith(
              color: muted,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SupportingLine extends StatelessWidget {
  const _SupportingLine({required this.passenger});

  final Passenger passenger;

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);
    final style = CaptainTypography.labelSmall(context).copyWith(
      color: muted,
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
    );
    final phone = passenger.phone.trim();

    return Row(
      children: [
        // The station is `Expanded` and the number is not: a clipped phone
        // number is a *different* number, while a clipped station name costs a
        // word the captain is already looking at out of the windscreen. So the
        // name is the one that gives way. `Flexible` on the number keeps it
        // ellipsising rather than overflowing in the impossible case.
        if (passenger.pickupPoint.isNotEmpty)
          Expanded(
            child: Text(
              passenger.pickupPoint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        if (passenger.pickupPoint.isNotEmpty && phone.isNotEmpty)
          Text(' · ', style: style),
        if (phone.isNotEmpty)
          // A phone number is an identifier: RTL would reorder its groups and
          // hand the captain a number that dials someone else.
          Flexible(
            child: Directionality(
              textDirection: CaptainTextDirection.ofIdentifier(phone),
              child: Text(
                phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
      ],
    );
  }
}

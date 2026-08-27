import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';

/// What the rider already holds on this departure, so a second booking is a
/// deliberate act rather than an accidental duplicate. The status itself is on
/// the badge beside it, so this only counts the seats.
///
/// A bare icon + label row rather than its own tinted pill: it sits on the
/// card's status strip, which is already carrying that tint, and a pill inside
/// a tinted strip reads as a panel inside a panel.
class HomeTripBookedNote extends StatelessWidget {
  const HomeTripBookedNote({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final accent = trip.bookedStatus!.accent;
    final seats = trip.bookedSeats;

    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 15, color: accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            seats > 1
                ? context.l10n.home_youBookedSeats(seats)
                : context.l10n.home_youBookedThis,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

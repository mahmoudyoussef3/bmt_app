import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_attention_copy.dart';

/// One line on a My Trips card saying why this booking is not settled.
///
/// The card's status badge reads off the *journey* axis, so before this every
/// unpaid, unreviewed and rejected booking in the list looked identical to a
/// confirmed one — the 17 `reserved` bookings in production all said "Upcoming".
/// This is the difference, kept to a single line so the list stays scannable;
/// the full explanation lives on Trip Details.
class TripCardAttentionStrip extends StatelessWidget {
  const TripCardAttentionStrip({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final copy = tripAttentionCopy(context, trip);
    if (copy == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: copy.color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(copy.icon, size: 15, color: copy.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                copy.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: copy.color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

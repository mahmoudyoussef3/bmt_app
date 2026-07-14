import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_card.dart';

/// The rider's own seats, soonest first. Capped at three so a frequent rider's
/// bookings never push the departures feed off the screen.
class HomeBookingsList extends StatelessWidget {
  const HomeBookingsList({
    super.key,
    required this.bookings,
    required this.onTrack,
    this.previewCount = 3,
  });

  final List<HomeBookingData> bookings;
  final ValueChanged<HomeBookingData> onTrack;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final visible = bookings.take(previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final booking in visible) ...[
          HomeBookingCard(booking: booking, onTrack: onTrack),
          if (booking != visible.last) const SizedBox(height: ClientSpacing.sm),
        ],
      ],
    );
  }
}

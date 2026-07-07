import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A labelled value column (Booking ref, Seat) inside [TripBoardingCard].
class BoardingField extends StatelessWidget {
  const BoardingField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed tear-line that gives the boarding pass its ticket character.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(
          28,
          (i) => Expanded(
            child: Container(
              height: 1.4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: i.isEven
                  ? ClientColors.borderStrongFor(context)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

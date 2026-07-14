import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A labelled value column (Booking ref, Seat) inside [TripBoardingCard].
///
/// The value is set in a tabular-figure style — a reference and a seat code are
/// read character by character, out loud, to a captain.
class BoardingField extends StatelessWidget {
  const BoardingField({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;

  /// Draws the value in brand color at ticket scale — used for the seat, the
  /// one thing a passenger looks up at the door.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context).copyWith(
            fontSize: emphasis ? 22 : 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: emphasis
                ? ClientColors.primaryFor(context)
                : ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}

/// One "Board at …" / "Departs …" line on the boarding pass stub.
class BoardingStubLine extends StatelessWidget {
  const BoardingStubLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: ClientColors.textTertiaryFor(context)),
        const SizedBox(width: 10),
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: ClientTypography.bodySmall(context).copyWith(
              fontWeight: FontWeight.w800,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
        ),
      ],
    );
  }
}

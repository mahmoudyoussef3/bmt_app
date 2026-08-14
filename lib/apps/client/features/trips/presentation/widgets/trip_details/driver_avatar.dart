import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The driver's initials avatar inside [TripDriverCard].
///
/// Uses the brand container pair rather than the light-mode-only
/// `primaryLight`, so the initials stay readable in dark mode.
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({super.key, required this.initials, this.radius = 24});

  final String initials;

  /// Radius in logical pixels. The captain row runs at 24 — an avatar is the
  /// section's identity mark, not its headline.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ClientColors.primaryContainerFor(context),
        border: Border.all(
          color: ClientColors.primaryFor(context).withAlpha(46),
          width: 1.5,
        ),
      ),
      child: Text(
        initials,
        maxLines: 1,
        style: ClientTypography.headingSmall(context).copyWith(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w800,
          color: ClientColors.onPrimaryContainerFor(context),
        ),
      ),
    );
  }
}

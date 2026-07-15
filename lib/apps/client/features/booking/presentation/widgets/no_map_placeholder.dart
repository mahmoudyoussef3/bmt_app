import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Graceful fallback shown wherever a route/trip map would render but no
/// valid stop coordinates are available — the rest of the screen stays
/// usable rather than failing (spec FR-007).
class NoMapPlaceholder extends StatelessWidget {
  const NoMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ClientColors.surfaceMutedFor(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 48,
              color: ClientColors.journeySlate,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.booking_mapCoordinatesUnavailable,
              style: ClientTypography.labelLarge(context),
            ),
          ],
        ),
      ),
    );
  }
}

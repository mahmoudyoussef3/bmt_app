import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Shown when the rider has no confirmed booking to track.
///
/// This is the state the old screen never had: with no trip it still rendered a
/// map, a timeline and a driver card built out of placeholders, which is why it
/// looked like it was showing fake data — it was. Now it says what happened and
/// offers the way forward.
class TrackingEmptyView extends StatelessWidget {
  const TrackingEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              size: 56,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.tracking_emptyTitle,
              textAlign: TextAlign.center,
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tracking_emptyBody,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 24),
            ClientButton(
              label: l10n.tracking_emptyAction,
              expand: false,
              onPressed: () =>
                  Navigator.of(context).pushNamed('/booking/search'),
            ),
          ],
        ),
      ),
    );
  }
}

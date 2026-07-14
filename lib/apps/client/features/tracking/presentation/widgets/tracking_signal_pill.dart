import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

import '../formatters/tracking_labels.dart';

/// The only thing floating over the map.
///
/// It answers the one question the map itself cannot: *can I trust this dot?*
/// Everything else the old map card carried — the captain's name, the plate,
/// the ETA — belongs in the sheet, where it does not sit on top of the route
/// the rider is trying to read.
class TrackingSignalPill extends StatelessWidget {
  const TrackingSignalPill({
    super.key,
    required this.progress,
    required this.recordedAt,
    required this.labels,
  });

  final RouteProgressSnapshot? progress;
  final DateTime? recordedAt;
  final TrackingLabels labels;

  @override
  Widget build(BuildContext context) {
    final l10n = labels.l10n;
    final hasFix = progress?.hasVehicleFix ?? false;
    final isStale = progress?.isStale ?? false;
    final isOffRoute = progress?.isOffRoute ?? false;

    final (color, text) = switch ((hasFix, isStale, isOffRoute)) {
      (false, _, _) => (ClientColors.journeySlate, l10n.tracking_signalNone),
      (_, true, _) => (ClientColors.journeyAmber, l10n.tracking_signalStale),
      (_, _, true) => (ClientColors.journeyAmber, l10n.tracking_signalOffRoute),
      _ => (ClientColors.journeyCyan, l10n.tracking_signalLive),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(240),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          if (hasFix) ...[
            const SizedBox(width: 6),
            Text(
              labels.signalAge(recordedAt),
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
          ],
        ],
      ),
    );
  }
}

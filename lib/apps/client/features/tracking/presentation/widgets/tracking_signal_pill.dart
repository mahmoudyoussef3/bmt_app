import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

import '../../domain/entities/vehicle_feed.dart';
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
    this.freshness,
    this.link,
  });

  final RouteProgressSnapshot? progress;
  final DateTime? recordedAt;
  final TrackingLabels labels;

  /// The tracking bloc's authoritative freshness, when the pill is being driven
  /// from it. Preferred over [RouteProgressSnapshot.isStale] because the two
  /// answer slightly different questions on different thresholds: the snapshot's
  /// flag is about when ETAs stop being trustworthy, this one is about when the
  /// *dot* stops being trustworthy, and the rider is asking about the dot.
  final TrackingFreshness? freshness;

  /// Health of the feed. A fresh position arriving by catch-up poll is still
  /// worth distinguishing from one arriving live.
  final TrackingLink? link;

  @override
  Widget build(BuildContext context) {
    final l10n = labels.l10n;
    final hasFix = progress?.hasVehicleFix ?? false;
    final isStale = freshness?.isStale ?? progress?.isStale ?? false;
    final isOffRoute = progress?.isOffRoute ?? false;
    final activeLink = link;
    final isReconnecting =
        hasFix && !isStale && activeLink != null && !activeLink.isConnected;

    final (color, text) = switch ((hasFix, isStale, isReconnecting, isOffRoute)) {
      (false, _, _, _) => (ClientColors.journeySlate, l10n.tracking_signalNone),
      (_, true, _, _) => (ClientColors.journeyAmber, l10n.tracking_signalStale),
      (_, _, true, _) => (
        ClientColors.journeyAmber,
        l10n.tracking_signalReconnecting,
      ),
      (_, _, _, true) => (
        ClientColors.journeyAmber,
        l10n.tracking_signalOffRoute,
      ),
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

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import '../../../domain/entities/tracking_trip.dart';
import '../../formatters/tracking_focus.dart';
import '../../formatters/tracking_labels.dart';
import 'tracking_route_progress_bar.dart';

/// The top of the sheet, and the only place an ETA appears.
///
/// The old screen printed the arrival time in three places at once (a hero
/// panel, the stop list header, and a card on the map) which is how a rider
/// ends up not believing any of them. There is one number here, it is the one
/// the rider is waiting on, and it says where it came from.
class TrackingStatusHeader extends StatelessWidget {
  const TrackingStatusHeader({
    super.key,
    required this.trip,
    required this.progress,
    required this.labels,
  });

  final TrackingTripData trip;
  final RouteProgressSnapshot? progress;
  final TrackingLabels labels;

  @override
  Widget build(BuildContext context) {
    final focus = TrackingFocus.of(trip, progress);
    final l10n = labels.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.headline(trip.tripState),
          style: ClientTypography.headingSmall(context),
        ),
        const SizedBox(height: 12),
        if (trip.tripState.isFinished)
          _Caption(text: l10n.tracking_completedBody)
        else ...[
          _Hero(
            label: focus.isBoarding
                ? l10n.tracking_etaToYourStop
                : l10n.tracking_etaToDestination,
            value: _value(focus),
            caption: _caption(focus),
          ),
          const SizedBox(height: 14),
          TrackingRouteProgressBar(
            fraction: progress?.routeFraction ?? 0,
            remainingLabel: labels.stopsRemaining(
              progress?.remainingStopCount ?? 0,
            ),
          ),
        ],
      ],
    );
  }

  /// Before any GPS fix the honest answer is the published schedule, not a
  /// countdown dressed up as live.
  String _value(TrackingFocus focus) {
    if (focus.hasTarget && focus.eta != null) {
      return labels.countdown(focus.eta);
    }
    final scheduled = labels.clock(trip.departureAt);
    return scheduled == null
        ? labels.l10n.tracking_etaUnavailable
        : labels.l10n.tracking_departsAt(scheduled);
  }

  String? _caption(TrackingFocus focus) {
    if (focus.hasTarget && focus.eta != null) {
      return labels.etaSource(focus.confidence);
    }
    return trip.hasLiveVehicleLocation
        ? null
        : labels.l10n.tracking_sourceScheduled;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: ClientTypography.displayMedium(
            context,
          ).copyWith(color: ClientColors.primaryFor(context)),
        ),
        if (text != null) ...[const SizedBox(height: 2), _Caption(text: text)],
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ClientTypography.labelSmall(
        context,
      ).copyWith(color: ClientColors.textTertiaryFor(context)),
    );
  }
}

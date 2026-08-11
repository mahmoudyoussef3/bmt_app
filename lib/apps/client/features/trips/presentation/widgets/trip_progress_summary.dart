import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

/// The real route-completion readout inside [TripLiveTrackingCard], with a
/// graceful fallback whenever the live engine has nothing to show yet —
/// never a fabricated percentage.
class TripProgressSummary extends StatelessWidget {
  const TripProgressSummary({super.key, required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    
    final progress = switch (state) {
      TrackingLoading() => null,
      TrackingError() => null,
      TrackingEmpty() => null,
      TrackingLoaded(:final progress) => progress,
    };

    if (progress == null || !progress.hasVehicleFix) {
      return _hint(context, switch (state) {
        TrackingLoading() => context.l10n.trips_liveLoadingPosition,
        TrackingError() => context.l10n.trips_livePositionUnavailable,
        _ => context.l10n.trips_liveWaitingForVehicle,
      });
    }

    final percent = (progress.routeFraction.clamp(0.0, 1.0) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppProgressBar(progress: progress.routeFraction),
        const SizedBox(height: 8),
        Text(
          context.l10n.trips_liveRouteCoveredPercent(percent),
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Text(
      text,
      style: ClientTypography.bodySmall(
        context,
      ).copyWith(color: ClientColors.textSecondaryFor(context)),
    );
  }
}

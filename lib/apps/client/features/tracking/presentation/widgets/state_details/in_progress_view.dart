import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_eta_panel.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_misc_widgets.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_stops_timeline.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Sheet content while the trip is live on the route: hero ETA, smart
/// per-stop timeline, and the latest driver-sent location metrics.
class InProgressView extends StatelessWidget {
  const InProgressView({
    super.key,
    required this.progress,
    required this.riderPickupName,
    required this.riderBoarded,
    required this.fallbackArrival,
    required this.speedLabel,
    required this.gpsLabel,
    required this.updatedLabel,
  });

  final RouteProgressSnapshot? progress;
  final String riderPickupName;
  final bool riderBoarded;
  final DateTime? fallbackArrival;
  final String speedLabel;
  final String gpsLabel;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackingEtaPanel(
          progress: progress,
          riderPickupName: riderPickupName,
          riderBoarded: riderBoarded,
          fallbackArrival: fallbackArrival,
        ),
        const SizedBox(height: 16),
        TrackingStopsTimeline(
          progress: progress,
          riderPickupName: riderPickupName,
          riderBoarded: riderBoarded,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TrackingMetricItem(
                icon: Icons.speed_rounded,
                label: 'Speed',
                value: speedLabel,
                color: ClientColors.primary,
              ),
              TrackingMetricItem(
                icon: Icons.location_on_rounded,
                label: 'GPS',
                value: gpsLabel,
                color: ClientColors.journeyCyan,
              ),
              TrackingMetricItem(
                icon: Icons.update_rounded,
                label: 'Updated',
                value: updatedLabel,
                color: scheme.tertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

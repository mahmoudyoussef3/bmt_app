import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// Hero ETA card driven by the route progress engine.
///
/// Until the rider boards, it counts down to *their* pickup stop; afterwards
/// (or when the pickup is unknown) it tracks the destination. A progress bar
/// shows how much of the route is covered, and the caption is honest about
/// where the estimate comes from (live GPS, inference, or the schedule).
class TrackingEtaPanel extends StatelessWidget {
  const TrackingEtaPanel({
    super.key,
    required this.progress,
    this.riderPickupName,
    this.riderBoarded = false,
    this.fallbackArrival,
  });

  final RouteProgressSnapshot? progress;
  final String? riderPickupName;
  final bool riderBoarded;

  /// Trip-level scheduled arrival, shown when the engine has nothing better.
  final DateTime? fallbackArrival;

  @override
  Widget build(BuildContext context) {
    final target = _target();
    final now = DateTime.now();
    final (value, unit) = _headline(target, now);
    final isPickupTarget =
        target != null && progress?.destination != target;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPickupTarget
                          ? 'Bus reaches your stop in'
                          : 'Estimated arrival in',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: ClientColors.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _caption(target, now),
                      style: TextStyle(
                        fontSize: 11,
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ClientColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPickupTarget
                      ? Icons.hail_rounded
                      : Icons.av_timer_rounded,
                  size: 28,
                  color: ClientColors.primary,
                ),
              ),
            ],
          ),
          if (progress != null &&
              progress!.totalRouteMeters > 0 &&
              progress!.phase == TripProgressPhase.enRoute) ...[
            const SizedBox(height: 14),
            _RouteProgressBar(progress: progress!),
          ],
        ],
      ),
    );
  }

  /// The stop the rider cares about right now: their own pickup while they
  /// are still waiting for the bus, the destination afterwards.
  StopProgress? _target() {
    final snapshot = progress;
    if (snapshot == null || snapshot.stops.isEmpty) return null;
    if (!riderBoarded) {
      final pickup = snapshot.stopByName(riderPickupName);
      if (pickup != null && !pickup.isVisited) return pickup;
    }
    return snapshot.destination;
  }

  (String, String) _headline(StopProgress? target, DateTime now) {
    final eta = target?.eta ?? fallbackArrival;
    if (eta == null) return ('--', 'awaiting signal');
    final minutes = eta.difference(now).inMinutes;
    if (minutes <= 0) return ('Now', 'arriving');
    if (minutes > 90) {
      final hours = minutes / 60;
      return (hours.toStringAsFixed(1), 'hours');
    }
    return ('$minutes', minutes == 1 ? 'minute' : 'minutes');
  }

  String _caption(StopProgress? target, DateTime now) {
    final snapshot = progress;
    if (snapshot == null || !snapshot.hasVehicleFix) {
      return 'Based on the published schedule';
    }
    if (snapshot.isOffRoute) {
      return 'Bus took a detour — estimate may shift';
    }
    if (snapshot.isStale) {
      return 'GPS signal lost — showing the schedule';
    }
    return switch (target?.etaConfidence) {
      EtaConfidence.live => 'Live estimate from the bus GPS',
      EtaConfidence.estimated => 'Estimate — bus is currently stopped',
      EtaConfidence.scheduled => 'Based on the published schedule',
      _ => 'Waiting for enough data to estimate',
    };
  }
}

class _RouteProgressBar extends StatelessWidget {
  const _RouteProgressBar({required this.progress});

  final RouteProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final kmLeft = progress.remainingMeters / 1000;
    final stopsLeft = progress.remainingStopCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: progress.routeFraction),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              color: ClientColors.primary,
              backgroundColor: ClientColors.borderFor(context),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(progress.routeFraction * 100).round()}% of route · '
          '${kmLeft < 10 ? kmLeft.toStringAsFixed(1) : kmLeft.round()} km left'
          '${stopsLeft > 0 ? ' · $stopsLeft ${stopsLeft == 1 ? 'stop' : 'stops'} ahead' : ''}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}

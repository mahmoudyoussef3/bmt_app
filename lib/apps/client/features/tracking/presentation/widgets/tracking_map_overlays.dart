import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';

import '../../domain/entities/tracking_trip.dart';

/// Bottom strip over the live map describing the GPS feed state.
class TrackingMapStatusStrip extends StatelessWidget {
  const TrackingMapStatusStrip({
    super.key,
    required this.sample,
    required this.currentState,
  });

  final VehicleSample? sample;
  final TrackingTripState currentState;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, label) = _describe(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context).withAlpha(235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(icon, color: tone, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
            ),
            if (sample != null && sample!.isMoving && !sample!.isStale)
              Text(
                '${sample!.speedKmh.round()} km/h',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ClientColors.journeyGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _describe(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);
    if (currentState == TrackingTripState.completed) {
      return (Icons.flag_rounded, ClientColors.journeyGreen, 'Trip completed');
    }
    final current = sample;
    if (current == null) {
      return (
        Icons.location_searching_rounded,
        muted,
        'Waiting for captain location',
      );
    }
    final age = DateTime.now().difference(current.fixRecordedAt);
    final ago = age.inMinutes < 1
        ? 'just now'
        : '${age.inMinutes} min ago';
    if (current.isStale) {
      return (
        Icons.gps_off_rounded,
        Theme.of(context).colorScheme.error,
        'Signal lost — last update $ago',
      );
    }
    return (
      Icons.my_location_rounded,
      ClientColors.journeyGreen,
      'Live location — updated $ago',
    );
  }
}

/// Fallback panel when the trip has no coordinates to draw at all.
class TrackingNoMapDataPanel extends StatelessWidget {
  const TrackingNoMapDataPanel({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, color: ClientColors.primary, size: 40),
          const SizedBox(height: 10),
          Text(
            'Map data unavailable',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No route coordinates were found for this trip.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 14),
          ClientButton.secondary(
            label: 'Refresh',
            expand: false,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

/// Stop marker whose look follows the route progress engine's visit state:
/// visited stops turn green with a check, the stop the bus is at pulses,
/// the next stop shows a bold ring, and future stops stay muted dots.
class TrackingProgressStopMarker extends StatelessWidget {
  const TrackingProgressStopMarker({
    super.key,
    required this.status,
    required this.pulseValue,
    this.isDestination = false,
  });

  final StopVisitStatus status;

  /// 0..1 sweep from the map's shared pulse controller; animates the halo of
  /// the stop the vehicle is arriving at.
  final double pulseValue;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      StopVisitStatus.departed => _core(
        size: 22,
        color: ClientColors.journeyGreen,
        child: const Icon(Icons.check, size: 13, color: Colors.white),
      ),
      StopVisitStatus.arrived => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26 + 16 * pulseValue,
            height: 26 + 16 * pulseValue,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.primary.withAlpha(
                (90 * (1 - pulseValue)).round(),
              ),
            ),
          ),
          _core(
            size: 26,
            color: ClientColors.primary,
            child: const Icon(
              Icons.directions_bus_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
      StopVisitStatus.next => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24 + 10 * pulseValue,
            height: 24 + 10 * pulseValue,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.primary.withAlpha(
                (60 * (1 - pulseValue)).round(),
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ClientColors.primary, width: 3.5),
            ),
          ),
        ],
      ),
      StopVisitStatus.upcoming => isDestination
          ? _core(
              size: 26,
              color: Colors.white,
              border: scheme.tertiary,
              child: Icon(
                Icons.location_on_rounded,
                size: 16,
                color: scheme.tertiary,
              ),
            )
          : Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: ClientColors.borderFor(context),
                  width: 2.5,
                ),
              ),
            ),
    };
  }

  Widget _core({
    required double size,
    required Color color,
    required Widget child,
    Color? border,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: border == null ? null : Border.all(color: border, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// Circular start/end stop badge used on the tracking map.
class TrackingStopMarker extends StatelessWidget {
  const TrackingStopMarker({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

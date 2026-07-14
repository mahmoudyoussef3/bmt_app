import 'package:flutter/material.dart';

import 'package:bmt_app/core/tracking/vehicle_fix.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../../domain/entities/tracking_point.dart';

/// The vehicle on the map: the interpolating track controller, and the halo
/// that breathes around it.
///
/// The halo only animates while there is a live vehicle to animate around. An
/// always-repeating controller repaints the marker layer forever, on a screen a
/// rider may leave open for the length of a bus journey.
class TrackingMapVehicle {
  TrackingMapVehicle({required TickerProvider vsync})
    : track = VehicleTrackController(vsync: vsync),
      pulse = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 1500),
      );

  final VehicleTrackController track;
  final AnimationController pulse;

  /// The interpolated position the marker is actually drawn at — which lags the
  /// raw fix, and is what the camera should follow so it eases rather than
  /// jumping stop-to-stop.
  VehicleSample? get sample => track.sample;

  void feed(TrackingPoint? fix) {
    if (fix == null) {
      if (pulse.isAnimating) pulse.stop();
      return;
    }
    if (!pulse.isAnimating) pulse.repeat(reverse: true);
    track.addFix(
      VehicleFix(
        latitude: fix.latitude,
        longitude: fix.longitude,
        recordedAt: fix.recordedAt ?? DateTime.now(),
        headingDegrees: fix.heading,
        speedMetersPerSecond: fix.speed,
        accuracyMeters: fix.accuracy,
      ),
    );
  }

  void addListener(VoidCallback listener) => track.addListener(listener);

  void removeListener(VoidCallback listener) => track.removeListener(listener);

  void dispose() {
    track.dispose();
    pulse.dispose();
  }
}

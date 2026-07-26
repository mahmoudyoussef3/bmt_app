import 'package:flutter/material.dart';

import 'package:bmt_app/core/tracking/vehicle_fix.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../../domain/entities/captain_location_fix.dart';

/// The captain's own vehicle on the map: the interpolating track controller and
/// the halo that breathes around it while a fix is fresh.
///
/// Fed from the device's local GPS rather than the backend — on the captain's
/// map the vehicle *is* the captain. The shared [VehicleTrackController] does
/// the same easing and heading-smoothing the client map uses, so a captain and
/// a rider watching the same trip see the marker move identically.
class CaptainMapVehicle {
  CaptainMapVehicle({required TickerProvider vsync})
    : track = VehicleTrackController(vsync: vsync),
      pulse = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 1500),
      );

  final VehicleTrackController track;
  final AnimationController pulse;

  /// The interpolated position the marker is actually drawn at — which the
  /// camera should follow so it eases rather than jumping fix-to-fix.
  VehicleSample? get sample => track.sample;

  void feed(CaptainLocationFix? fix) {
    if (fix == null) {
      if (pulse.isAnimating) pulse.stop();
      return;
    }
    if (!pulse.isAnimating) pulse.repeat(reverse: true);
    track.addFix(
      VehicleFix(
        latitude: fix.latitude,
        longitude: fix.longitude,
        recordedAt: fix.recordedAt,
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

import 'package:flutter/material.dart';

import 'package:bmt_app/core/tracking/vehicle_fix.dart';
import 'package:bmt_app/core/tracking/vehicle_sample.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';

import '../../../domain/entities/captain_location_fix.dart';

class CaptainMapVehicle {
  CaptainMapVehicle({required TickerProvider vsync})
    : track = VehicleTrackController(vsync: vsync),
      pulse = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 1500),
      );

  final VehicleTrackController track;
  final AnimationController pulse;

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

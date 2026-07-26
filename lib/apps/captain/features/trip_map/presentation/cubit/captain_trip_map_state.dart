import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../domain/entities/captain_location_fix.dart';
import '../../domain/entities/pickup_plan.dart';

/// Where the trip stands, from the captain map's point of view. Mirrors the
/// operational statuses the map can be opened on; it never invents a status the
/// trip's own lifecycle doesn't have.
enum CaptainMapPhase { boarding, underway, completed, cancelled }

extension CaptainMapPhaseX on CaptainMapPhase {
  bool get isLive =>
      this == CaptainMapPhase.boarding || this == CaptainMapPhase.underway;
  bool get isUnderway => this == CaptainMapPhase.underway;
  bool get isFinished =>
      this == CaptainMapPhase.completed || this == CaptainMapPhase.cancelled;
}

/// The health of the captain's own GPS feed — the traffic light that tells the
/// captain whether their position is really being tracked, so a failed feed is
/// never mistaken for a working one.
///
/// There is deliberately no age-based "stale": the position stream is
/// distance-filtered, so a bus waiting at a stop legitimately emits nothing.
/// A genuine loss surfaces as a stream error ([lost]) or a service/permission
/// gate that never opened ([unavailable]), not as silence from a parked bus.
enum GpsHealth {
  /// Fixes are flowing; the vehicle is live on the map.
  live,

  /// Service and permission are fine; waiting for the first fix.
  acquiring,

  /// We had a live feed and the sensor stopped (service switched off mid-trip).
  lost,

  /// Location service is off or permission was denied — no fix is possible.
  unavailable,
}

/// The single immutable state the map renders from.
///
/// One state object, not a union: the map is never blank once opened (the route
/// and the trip are known up front), so loading passengers, a failed status
/// write, or a lost signal are all refinements layered onto a screen that stays
/// up — an action error never replaces the map.
class CaptainTripMapState {
  const CaptainTripMapState({
    required this.tripId,
    required this.phase,
    required this.gpsHealth,
    this.gpsMessage,
    this.fix,
    this.progress,
    this.pickup = const PickupPlan.empty(),
    this.activePickupProgress,
    this.pendingRiderId,
    this.arrivingStopId,
    this.actionError,
    this.riderCount = 0,
    this.boardedCount = 0,
  });

  factory CaptainTripMapState.initial(String tripId, CaptainMapPhase phase) =>
      CaptainTripMapState(
        tripId: tripId,
        phase: phase,
        gpsHealth: GpsHealth.acquiring,
      );

  final String tripId;
  final CaptainMapPhase phase;

  final GpsHealth gpsHealth;

  /// A human reason for a degraded [gpsHealth] (denied permission, service off).
  final String? gpsMessage;

  /// The captain's latest own-device fix; null until the first one arrives.
  final CaptainLocationFix? fix;

  /// Route progress from the shared engine, fed by [fix].
  final RouteProgressSnapshot? progress;

  /// The pickup sequence grouped by boarding stop.
  final PickupPlan pickup;

  /// Distance/ETA to the active pickup stop, from the progress engine; null when
  /// the active stop couldn't be matched to a route point (no coordinates).
  final StopProgress? activePickupProgress;

  /// The rider whose boarding status write is in flight (for a per-tile spinner).
  final String? pendingRiderId;

  /// The stop whose "arrived" write is in flight.
  final String? arrivingStopId;

  /// A transient action failure, shown without tearing down the map.
  final String? actionError;

  final int riderCount;
  final int boardedCount;

  bool get hasFix => fix != null;

  CaptainTripMapState copyWith({
    CaptainMapPhase? phase,
    GpsHealth? gpsHealth,
    Object? gpsMessage = _unset,
    CaptainLocationFix? fix,
    RouteProgressSnapshot? progress,
    PickupPlan? pickup,
    Object? activePickupProgress = _unset,
    Object? pendingRiderId = _unset,
    Object? arrivingStopId = _unset,
    Object? actionError = _unset,
    int? riderCount,
    int? boardedCount,
  }) {
    return CaptainTripMapState(
      tripId: tripId,
      phase: phase ?? this.phase,
      gpsHealth: gpsHealth ?? this.gpsHealth,
      gpsMessage: gpsMessage == _unset ? this.gpsMessage : gpsMessage as String?,
      fix: fix ?? this.fix,
      progress: progress ?? this.progress,
      pickup: pickup ?? this.pickup,
      activePickupProgress: activePickupProgress == _unset
          ? this.activePickupProgress
          : activePickupProgress as StopProgress?,
      pendingRiderId: pendingRiderId == _unset
          ? this.pendingRiderId
          : pendingRiderId as String?,
      arrivingStopId: arrivingStopId == _unset
          ? this.arrivingStopId
          : arrivingStopId as String?,
      actionError:
          actionError == _unset ? this.actionError : actionError as String?,
      riderCount: riderCount ?? this.riderCount,
      boardedCount: boardedCount ?? this.boardedCount,
    );
  }

  static const _unset = Object();
}

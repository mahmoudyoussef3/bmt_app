import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../domain/entities/captain_location_fix.dart';
import '../../domain/entities/pickup_plan.dart';

enum CaptainMapPhase { boarding, underway, completed, cancelled }

extension CaptainMapPhaseX on CaptainMapPhase {
  bool get isLive =>
      this == CaptainMapPhase.boarding || this == CaptainMapPhase.underway;
  bool get isUnderway => this == CaptainMapPhase.underway;
  bool get isFinished =>
      this == CaptainMapPhase.completed || this == CaptainMapPhase.cancelled;
}

enum GpsHealth { live, acquiring, lost, unavailable }

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

  final String? gpsMessage;

  final CaptainLocationFix? fix;

  final RouteProgressSnapshot? progress;

  final PickupPlan pickup;

  final StopProgress? activePickupProgress;

  final String? pendingRiderId;

  final String? arrivingStopId;

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
      gpsMessage: gpsMessage == _unset
          ? this.gpsMessage
          : gpsMessage as String?,
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
      actionError: actionError == _unset
          ? this.actionError
          : actionError as String?,
      riderCount: riderCount ?? this.riderCount,
      boardedCount: boardedCount ?? this.boardedCount,
    );
  }

  static const _unset = Object();
}

import 'package:equatable/equatable.dart';

import 'package:bmt_app/core/tracking/link_health.dart';

import '../../domain/entities/fleet_feed.dart';
import '../../domain/entities/live_ops_snapshot.dart';

/// The board's live view of where the fleet is.
///
/// One state class, not a union, and that is the opposite of the choice the
/// client's rider-facing Bloc made — for a reason. A rider watches one vehicle,
/// so "connecting", "unavailable" and "finished" are whole-screen answers. A desk
/// watches many, and they are never all in the same condition: one bus is live,
/// one went stale, one never reported. Per-vehicle condition therefore lives in
/// the map ([vehicles], each with its own health), and the only genuinely
/// screen-wide facts — is the link up, did the feed fail — are fields here.
///
/// Modelling this as a union would force the board to pick one vehicle's
/// condition to represent all of them, which is exactly the lie the operator
/// cannot afford.
class FleetTrackingState extends Equatable {
  const FleetTrackingState({
    this.vehicles = const {},
    this.link = TrackingLink.connected,
    this.isConnecting = true,
    this.failure,
    this.evaluatedAt,
  });

  /// Last known position per trip id, for every trip on the current roster.
  final Map<String, TrackedVehicle> vehicles;

  /// Health of the socket carrying positions.
  final TrackingLink link;

  /// True until the feed has reported its status for the first time.
  final bool isConnecting;

  /// Set when the feed itself fell over. Positions already on screen are kept —
  /// a failed socket is not a reason to erase the fleet's last known positions.
  final String? failure;

  /// The clock the board's health badges were last computed against.
  ///
  /// Carried in the state so that a freshness tick is a real, observable change:
  /// health is a function of *now*, and without a moving reference in the state a
  /// vehicle would go stale only when some unrelated rebuild happened to notice.
  final DateTime? evaluatedAt;

  bool get hasFailure => failure != null;

  /// A position for [tripId], or `null` if that trip has never reported one.
  TrackedVehicle? vehicle(String tripId) => vehicles[tripId];

  /// Health of one trip's feed at [now]. [TrackingHealth.unknown] when the trip
  /// has no position at all — distinct from `offline`, which means it had one and
  /// then went quiet.
  TrackingHealth healthOf(String tripId, DateTime now) =>
      vehicles[tripId]?.healthAt(now) ?? TrackingHealth.unknown;

  /// Trips whose feed is anything other than [TrackingHealth.live] — the ones an
  /// operator can no longer see moving.
  int atRiskCount(Iterable<String> tripIds, DateTime now) =>
      tripIds.where((id) => healthOf(id, now) != TrackingHealth.live).length;

  FleetTrackingState copyWith({
    Map<String, TrackedVehicle>? vehicles,
    TrackingLink? link,
    bool? isConnecting,
    String? failure,
    bool clearFailure = false,
    DateTime? evaluatedAt,
  }) {
    return FleetTrackingState(
      vehicles: vehicles ?? this.vehicles,
      link: link ?? this.link,
      isConnecting: isConnecting ?? this.isConnecting,
      failure: clearFailure ? null : (failure ?? this.failure),
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  /// Equatable compares [vehicles] with a deep collection equality, which here
  /// means: keys by value, and values by identity — [TrackedVehicle] does not
  /// override `==`.
  ///
  /// That is exactly the semantics wanted. Every accepted fix installs a *new*
  /// [TrackedVehicle], so an unequal map means a position genuinely changed,
  /// while a rebuild that re-derives the same map from the same entries compares
  /// equal and emits nothing. Comparing the map's identity instead would be
  /// cheaper by a constant and would report a change whenever the map was merely
  /// copied.
  @override
  List<Object?> get props => [
    vehicles,
    link,
    isConnecting,
    failure,
    evaluatedAt,
  ];
}

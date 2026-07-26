import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';

import '../entities/pickup_plan.dart';

/// Builds the [PickupPlan] for a trip from its route stops and manifest.
///
/// Riders board at named route stops, so a rider's pickup point is matched to a
/// route stop by name (case- and whitespace-insensitive, the same rule the
/// shared progress engine uses in `stopByName`). Riders whose pickup name
/// matches no stop are still shown — grouped after the mapped stops — so a
/// renamed or legacy pickup point never makes a paying rider vanish from the
/// captain's sequence.
///
/// Cancelled bookings are dropped entirely: they are not people the captain is
/// waiting for, and leaving them in would keep a resolved stop looking pending.
class PickupPlanner {
  const PickupPlanner._();

  static PickupPlan plan({
    required List<AssignedTripStop> stops,
    required List<Passenger> passengers,
  }) {
    // route stop name -> its position and coordinates.
    final byName = <String, _StopRef>{};
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final key = _normalize(stop.name);
      // First occurrence wins: if two stops share a name, a rider's pickup can
      // only sensibly mean the earlier one.
      byName.putIfAbsent(
        key,
        () => _StopRef(
          index: i,
          id: stop.id,
          name: stop.name,
          latitude: stop.latitude,
          longitude: stop.longitude,
        ),
      );
    }

    // Group riders, preserving first-seen order for the unmatched buckets.
    final groups = <String, _Group>{};
    for (final passenger in passengers) {
      if (passenger.status == PassengerBoardingStatus.cancelled) continue;

      final ref = byName[_normalize(passenger.pickupPoint)];
      final key = ref != null
          ? 'idx:${ref.index}'
          : 'name:${_normalize(passenger.pickupPoint)}';

      final group = groups.putIfAbsent(
        key,
        () => _Group(
          name: ref?.name ?? passenger.pickupPoint,
          index: ref?.index,
          id: ref?.id,
          latitude: ref?.latitude,
          longitude: ref?.longitude,
        ),
      );
      group.riders.add(
        PickupRider(
          tripPassengerId: passenger.id,
          name: passenger.name,
          seat: passenger.seat,
          phone: passenger.phone,
          status: passenger.status,
        ),
      );
    }

    // Mapped stops in route order, then the unmatched ones after them.
    final mapped = groups.values.where((g) => g.index != null).toList()
      ..sort((a, b) => a.index!.compareTo(b.index!));
    final unmatched = groups.values.where((g) => g.index == null).toList();

    final ordered = [...mapped, ...unmatched]
        .map((g) => g.toPickupStop())
        .toList(growable: false);

    // The active pickup is the first stop that still has a pending rider.
    int? activeIndex;
    for (var i = 0; i < ordered.length; i++) {
      if (!ordered[i].isResolved) {
        activeIndex = i;
        break;
      }
    }

    return PickupPlan(stops: ordered, activeIndex: activeIndex);
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}

class _StopRef {
  const _StopRef({
    required this.index,
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final int index;
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
}

class _Group {
  _Group({
    required this.name,
    required this.index,
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final int? index;
  final String? id;
  final double? latitude;
  final double? longitude;
  final List<PickupRider> riders = [];

  PickupStop toPickupStop() => PickupStop(
    name: name,
    riders: List.unmodifiable(riders),
    stopIndex: index,
    stopId: id,
    latitude: latitude,
    longitude: longitude,
  );
}

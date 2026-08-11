import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';

import '../entities/pickup_plan.dart';

class PickupPlanner {
  const PickupPlanner._();

  static PickupPlan plan({
    required List<AssignedTripStop> stops,
    required List<Passenger> passengers,
  }) {
    final byName = <String, _StopRef>{};
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final key = _normalize(stop.name);
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

    final mapped = groups.values.where((g) => g.index != null).toList()
      ..sort((a, b) => a.index!.compareTo(b.index!));
    final unmatched = groups.values.where((g) => g.index == null).toList();

    final ordered = [
      ...mapped,
      ...unmatched,
    ].map((g) => g.toPickupStop()).toList(growable: false);

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

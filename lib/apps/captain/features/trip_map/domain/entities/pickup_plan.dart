import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';

class PickupRider {
  const PickupRider({
    required this.tripPassengerId,
    required this.name,
    required this.seat,
    required this.phone,
    required this.status,
  });

  final String tripPassengerId;
  final String name;
  final String seat;
  final String phone;
  final PassengerBoardingStatus status;

  bool get isPending => status == PassengerBoardingStatus.pending;
  bool get hasBoarded => status == PassengerBoardingStatus.boarded;
  bool get isAbsent => status == PassengerBoardingStatus.absent;

  bool get isResolved => !isPending;
}

class PickupStop {
  const PickupStop({
    required this.name,
    required this.riders,
    this.stopIndex,
    this.stopId,
    this.latitude,
    this.longitude,
  });

  final String name;

  final List<PickupRider> riders;

  final int? stopIndex;

  final String? stopId;

  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  int get pendingCount => riders.where((r) => r.isPending).length;
  int get boardedCount => riders.where((r) => r.hasBoarded).length;
  int get absentCount => riders.where((r) => r.isAbsent).length;
  int get total => riders.length;

  bool get isResolved => riders.every((r) => r.isResolved);
}

class PickupPlan {
  const PickupPlan({required this.stops, required this.activeIndex});

  const PickupPlan.empty() : stops = const [], activeIndex = null;

  final List<PickupStop> stops;

  final int? activeIndex;

  PickupStop? get active => activeIndex == null ? null : stops[activeIndex!];

  PickupStop? get upcoming {
    final index = activeIndex;
    if (index == null || index + 1 >= stops.length) return null;
    return stops[index + 1];
  }

  bool get isEmpty => stops.isEmpty;

  bool get isAllResolved => stops.isNotEmpty && activeIndex == null;

  int get totalRiders => stops.fold(0, (sum, stop) => sum + stop.total);

  int get totalBoarded => stops.fold(0, (sum, stop) => sum + stop.boardedCount);

  int get totalPending => stops.fold(0, (sum, stop) => sum + stop.pendingCount);
}

import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../entities/station_passenger.dart';

abstract class StationProgressRepository {
  Stream<StationBoard> watchBoard(String tripId);

  Future<void> arriveAtStation(String tripId);

  /// Refused by the database unless both departure conditions hold; throws a
  /// [StationActionException] carrying which one did not.
  Future<void> departStation(String tripId);

  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  });

  Future<List<StationPassenger>> passengersAt({
    required String tripId,
    String? routePointId,
    required String pointName,
  });
}

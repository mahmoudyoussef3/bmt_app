import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';

import '../entities/passenger.dart';

abstract class PassengerManifestRepository {
  Future<List<Passenger>> getTripPassengers(String tripId);
  Stream<void> watchPassengerUpdates(String tripId);

  /// [noShowReason] is required when [status] is
  /// [PassengerBoardingStatus.absent] — that path records why a paying rider is
  /// not travelling, and the database refuses it without one.
  Future<void> updatePassengerStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
    NoShowReason? noShowReason,
    String? note,
  });
}

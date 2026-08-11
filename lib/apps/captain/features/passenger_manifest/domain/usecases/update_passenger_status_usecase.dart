import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';

import '../entities/passenger.dart';
import '../repositories/passenger_manifest_repository.dart';

class UpdatePassengerStatusUseCase {
  const UpdatePassengerStatusUseCase(this._repository);

  final PassengerManifestRepository _repository;

  Future<void> call({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
    NoShowReason? noShowReason,
    String? note,
  }) => _repository.updatePassengerStatus(
    tripPassengerId: tripPassengerId,
    status: status,
    noShowReason: noShowReason,
    note: note,
  );
}

import '../entities/station_passenger.dart';
import '../repositories/station_progress_repository.dart';

class ResolveNoShowUseCase {
  const ResolveNoShowUseCase(this._repository);

  final StationProgressRepository _repository;

  Future<void> call({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) => _repository.resolveNoShow(
    passengerId: passengerId,
    reason: reason,
    note: note,
  );
}

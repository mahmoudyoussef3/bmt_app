import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../repositories/station_progress_repository.dart';

class WatchStationBoardUseCase {
  const WatchStationBoardUseCase(this._repository);

  final StationProgressRepository _repository;

  Stream<StationBoard> call(String tripId) => _repository.watchBoard(tripId);
}

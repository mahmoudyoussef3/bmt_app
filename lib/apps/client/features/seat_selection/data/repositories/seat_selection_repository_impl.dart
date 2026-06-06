import '../../domain/entities/seat_option.dart';
import '../../domain/repositories/seat_selection_repository.dart';
import '../datasources/mock_seat_selection_datasource.dart';

class SeatSelectionRepositoryImpl implements SeatSelectionRepository {
  const SeatSelectionRepositoryImpl(this._datasource);

  final MockSeatSelectionDatasource _datasource;

  @override
  Future<SeatSelectionData> getSeatSelectionData() async {
    final model = await _datasource.getSeatSelectionData();
    return model.toEntity();
  }
}

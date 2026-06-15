import '../../domain/entities/seat_option.dart';
import '../../domain/repositories/seat_selection_repository.dart';
import '../datasources/seat_selection_datasource.dart';

class SeatSelectionRepositoryImpl implements SeatSelectionRepository {
  const SeatSelectionRepositoryImpl(this._datasource);

  final SeatSelectionDatasource _datasource;

  @override
  Future<SeatSelectionData> getSeatSelectionData(String tripId) async {
    final model = await _datasource.getSeatSelectionData(tripId);
    return model.toEntity();
  }

  @override
  Future<String> bookTripSeat(Map<String, dynamic> params) {
    return _datasource.bookTripSeat(params);
  }
}

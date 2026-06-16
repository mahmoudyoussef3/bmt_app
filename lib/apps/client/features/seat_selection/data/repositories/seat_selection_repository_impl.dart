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
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  }) {
    return _datasource.lockTripSeat(tripId: tripId, seatId: seatId);
  }

  @override
  Future<Map<String, dynamic>> confirmSeatBooking(Map<String, dynamic> params) {
    return _datasource.confirmSeatBooking(params);
  }

  @override
  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params) {
    return _datasource.bookTripSeat(params);
  }
}

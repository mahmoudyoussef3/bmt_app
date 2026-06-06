import '../entities/seat_option.dart';

abstract class SeatSelectionRepository {
  Future<SeatSelectionData> getSeatSelectionData();
}

import '../entities/seat_option.dart';

abstract class SeatSelectionRepository {
  Future<SeatSelectionData> getSeatSelectionData(String tripId);
  Future<String> bookTripSeat(Map<String, dynamic> params);
}

import '../models/seat_selection_model.dart';

abstract class SeatSelectionDatasource {
  Future<SeatSelectionModel> getSeatSelectionData(String tripId);
  Future<String> bookTripSeat(Map<String, dynamic> params);
}

import '../entities/seat_release_data.dart';

abstract class SeatReleaseRepository {
  Future<SeatReleaseData> getSeatReleaseData();
}

import '../../domain/entities/seat_release_data.dart';
import '../../domain/repositories/seat_release_repository.dart';
import '../datasources/supabase_seat_release_datasource.dart';

class SeatReleaseRepositoryImpl implements SeatReleaseRepository {
  const SeatReleaseRepositoryImpl(this._datasource);

  final SeatReleaseDatasource _datasource;

  @override
  Future<SeatReleaseData> getSeatReleaseData() {
    return _datasource.getSeatReleaseData();
  }
}

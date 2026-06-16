import '../../domain/entities/check_in_result.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../datasources/check_in_datasource.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  const CheckInRepositoryImpl(this._dataSource);

  final CheckInDataSource _dataSource;

  @override
  Future<CheckInResult> checkPassenger({
    required String tripId,
    required String bookingId,
    required CheckInStatus status,
  }) async {
    return (await _dataSource.checkPassenger(
      tripId: tripId,
      bookingId: bookingId,
      status: status,
    )).toEntity();
  }
}

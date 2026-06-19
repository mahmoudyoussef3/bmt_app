import '../../domain/entities/tracking_trip.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/supabase_tracking_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._datasource);

  final SupabaseTrackingDatasource _datasource;

  @override
  Future<TrackingTripData> getTrackingTrip() async {
    final model = await _datasource.getTrackingTrip();
    return model.toEntity();
  }
}

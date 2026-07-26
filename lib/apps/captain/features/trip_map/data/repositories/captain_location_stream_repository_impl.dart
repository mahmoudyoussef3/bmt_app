import '../../domain/entities/captain_location_fix.dart';
import '../../domain/entities/location_gate.dart';
import '../../domain/repositories/captain_location_stream_repository.dart';
import '../datasources/captain_location_stream_datasource.dart';

class CaptainLocationStreamRepositoryImpl
    implements CaptainLocationStreamRepository {
  const CaptainLocationStreamRepositoryImpl(this._datasource);

  final CaptainLocationStreamDatasource _datasource;

  @override
  Future<LocationGate> ensureReady() => _datasource.ensureReady();

  @override
  Stream<CaptainLocationFix> watchPosition() => _datasource.watchPosition();
}

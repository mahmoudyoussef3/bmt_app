import '../../domain/repositories/captain_auth_repository.dart';
import '../datasources/captain_auth_datasource.dart';

class CaptainAuthRepositoryImpl implements CaptainAuthRepository {
  const CaptainAuthRepositoryImpl(this._datasource);

  final CaptainAuthDatasource _datasource;

  @override
  Future<void> signInWithPhone(String phone) =>
      _datasource.signInWithPhone(phone);

  @override
  Future<void> signOut() => _datasource.signOut();
}

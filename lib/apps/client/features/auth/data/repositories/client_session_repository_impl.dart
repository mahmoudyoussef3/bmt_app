import '../../domain/repositories/client_session_repository.dart';
import '../datasources/client_session_datasource.dart';

class ClientSessionRepositoryImpl implements ClientSessionRepository {
  const ClientSessionRepositoryImpl(this._datasource);

  final ClientSessionDatasource _datasource;

  /// The datasource already fails open on a lookup error and signs out a
  /// rejected session, so there is nothing to translate here.
  @override
  Future<bool> ensureClientSession() => _datasource.ensureClientSession();
}

import '../repositories/client_session_repository.dart';

class EnsureClientSessionUseCase {
  final ClientSessionRepository repository;

  EnsureClientSessionUseCase(this.repository);

  Future<bool> call() async {
    return repository.ensureClientSession();
  }
}

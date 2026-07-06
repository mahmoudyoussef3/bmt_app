import '../entities/captain_request.dart';
import '../repositories/captain_requests_repository.dart';

class GetCaptainRequestsUseCase {
  final CaptainRequestsRepository _repository;
  const GetCaptainRequestsUseCase(this._repository);

  Future<List<CaptainRequest>> call() => _repository.getRequests();
}

class WatchCaptainRequestsUseCase {
  final CaptainRequestsRepository _repository;
  const WatchCaptainRequestsUseCase(this._repository);

  Stream<List<CaptainRequest>> call() => _repository.watchRequests();
}

/// Links a newly created driver to the request that spawned it.
class ApproveCaptainRequestUseCase {
  final CaptainRequestsRepository _repository;
  const ApproveCaptainRequestUseCase(this._repository);

  Future<void> call({required String requestId, required String driverId}) =>
      _repository.approve(requestId: requestId, driverId: driverId);
}

class RejectCaptainRequestUseCase {
  final CaptainRequestsRepository _repository;
  const RejectCaptainRequestUseCase(this._repository);

  Future<void> call({required String requestId, required String reason}) =>
      _repository.reject(requestId: requestId, reason: reason);
}

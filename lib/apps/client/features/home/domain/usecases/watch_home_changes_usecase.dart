import '../repositories/home_repository.dart';

class WatchHomeChangesUseCase {
  const WatchHomeChangesUseCase(this._repository);

  final HomeRepository _repository;

  Stream<void> call() => _repository.watchHomeChanges();
}

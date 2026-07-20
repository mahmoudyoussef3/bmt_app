import '../entities/my_subscription.dart';
import '../repositories/packages_repository.dart';

class GetMySubscriptionUseCase {
  const GetMySubscriptionUseCase(this._repository);

  final PackagesRepository _repository;

  Future<MySubscription?> call() => _repository.getMySubscription();
}

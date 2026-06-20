import '../entities/subscription_request.dart';
import '../repositories/packages_repository.dart';

class CreateSubscriptionUseCase {
  const CreateSubscriptionUseCase(this._repository);

  final PackagesRepository _repository;

  Future<String> call(SubscriptionRequest request) {
    return _repository.createSubscription(request);
  }
}

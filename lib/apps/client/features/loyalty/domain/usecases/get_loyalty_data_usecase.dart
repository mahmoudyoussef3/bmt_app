import '../entities/loyalty_data.dart';
import '../repositories/loyalty_repository.dart';

class GetLoyaltyDataUseCase {
  const GetLoyaltyDataUseCase(this._repository);

  final LoyaltyRepository _repository;

  Future<LoyaltyData> call() => _repository.getLoyaltyData();
}

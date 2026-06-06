import '../entities/loyalty_data.dart';

abstract class LoyaltyRepository {
  Future<LoyaltyData> getLoyaltyData();
}

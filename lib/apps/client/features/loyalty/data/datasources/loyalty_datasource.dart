import '../../domain/entities/loyalty_data.dart';

abstract class LoyaltyDatasource {
  Future<LoyaltyData> getLoyaltyData();
}

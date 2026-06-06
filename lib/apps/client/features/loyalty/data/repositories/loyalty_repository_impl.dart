import '../../domain/entities/loyalty_data.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/mock_loyalty_datasource.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  const LoyaltyRepositoryImpl(this._datasource);

  final MockLoyaltyDatasource _datasource;

  @override
  Future<LoyaltyData> getLoyaltyData() => _datasource.getLoyaltyData();
}

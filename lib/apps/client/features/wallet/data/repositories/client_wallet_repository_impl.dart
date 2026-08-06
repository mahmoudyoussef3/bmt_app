import '../../domain/entities/client_wallet.dart';
import '../../domain/repositories/client_wallet_repository.dart';
import '../datasources/supabase_client_wallet_datasource.dart';

class ClientWalletRepositoryImpl implements ClientWalletRepository {
  const ClientWalletRepositoryImpl(this._datasource);

  final SupabaseClientWalletDatasource _datasource;

  @override
  Future<ClientWalletSummary> getSummary() => _datasource.getSummary();
}

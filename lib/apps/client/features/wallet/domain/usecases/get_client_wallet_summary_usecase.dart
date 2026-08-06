import '../entities/client_wallet.dart';
import '../repositories/client_wallet_repository.dart';

class GetClientWalletSummaryUseCase {
  const GetClientWalletSummaryUseCase(this._repository);

  final ClientWalletRepository _repository;

  Future<ClientWalletSummary> call() => _repository.getSummary();
}

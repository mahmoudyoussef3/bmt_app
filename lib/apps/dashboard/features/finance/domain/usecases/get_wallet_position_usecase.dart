import '../entities/finance_money_model.dart';
import '../repositories/finance_repository.dart';

/// Reads the wallet-side facts the three statements need (§7.3).
///
/// Finance owns the *reporting* of wallet liability; the wallet module owns
/// every decision that moves it. Keeping this a read-only use case is what stops
/// the two modules from becoming two places money can be changed.
class GetWalletPositionUseCase {
  final FinanceRepository _repository;

  const GetWalletPositionUseCase(this._repository);

  Future<WalletFinancePosition> call() => _repository.getWalletPosition();
}

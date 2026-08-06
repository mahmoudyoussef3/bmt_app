import '../entities/client_wallet.dart';

/// Read-only, and that is the whole contract.
///
/// A rider can see what each office owes them and how it got there. They cannot
/// move it: every credit and every debit is an office decision with an operator's
/// name attached, and V1 has no wallet spending at checkout. There is
/// deliberately no `redeem`, no `transfer` and no `withdraw` here — the previous
/// attempt at one zeroed a balance client-side, was silently denied by RLS, and
/// reported a payout that never happened.
abstract class ClientWalletRepository {
  Future<ClientWalletSummary> getSummary();
}

import 'refund_request.dart';
import 'wallet.dart';
import 'wallet_transaction.dart';
import 'wallet_vocabulary.dart';

/// Everything the wallet detail screen (surface 2) needs, resolved in one round
/// trip: who the customer is, what they hold, what it is made of, what is still
/// waiting on a decision, and the history that explains the number.
class WalletSummary {
  final WalletCustomer customer;
  final Wallet wallet;

  /// Absolute totals per kind — the strip under the balance. Context, not the
  /// headline: five KPI cards here would compete with the one number every
  /// conversation starts from (§8.2).
  final Map<WalletKind, double> totalsByKind;

  /// Requests still awaiting or mid-decision. Rendered inline as a banner rather
  /// than in a separate tab: an operator must not be able to issue a second
  /// refund while unaware one is already waiting. A control, not a convenience.
  final List<RefundRequest> pendingRefunds;

  final List<WalletTransaction> entries;

  const WalletSummary({
    required this.customer,
    required this.wallet,
    required this.totalsByKind,
    required this.pendingRefunds,
    required this.entries,
  });

  double totalFor(WalletKind kind) => totalsByKind[kind] ?? 0;

  bool get hasHistory => entries.isNotEmpty;
}

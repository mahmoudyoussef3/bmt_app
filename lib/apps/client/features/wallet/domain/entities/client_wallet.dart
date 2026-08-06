/// The rider's side of the wallet: read-only, per office.
///
/// A customer who books with three offices holds three wallets and sees three
/// labelled balances. That is the honest model — these are three separate credit
/// relationships with three separate businesses, and value collected by one
/// office is not spendable at another because there is no clearing mechanism
/// between them.
library;

enum ClientWalletEntryKind {
  refund('refund', 'استرداد'),
  cashback('cashback', 'كاش باك'),
  manualCredit('manual_credit', 'إضافة رصيد'),
  manualDebit('manual_debit', 'خصم'),
  walletSpend('wallet_spend', 'دفع من المحفظة'),
  walletTopup('wallet_topup', 'شحن'),
  reversal('reversal', 'تصحيح');

  const ClientWalletEntryKind(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ClientWalletEntryKind fromDb(String value) =>
      ClientWalletEntryKind.values.firstWhere(
        (kind) => kind.dbValue == value,
        orElse: () => ClientWalletEntryKind.manualCredit,
      );
}

/// One line of the rider's history.
class ClientWalletEntry {
  final String id;
  final int seq;
  final ClientWalletEntryKind kind;
  final String category;

  /// Signed — credits positive, debits negative.
  final double amount;

  /// The balance immediately after this entry. Shown because the rider's
  /// question is never "what was the amount", it is "why is my balance this".
  final double balanceAfter;

  /// `posted` or `reversed`. A reversed entry stays visible: nothing disappears
  /// from a ledger, and a line that vanished would look like a mistake was
  /// hidden.
  final String status;
  final String reason;
  final DateTime createdAt;

  const ClientWalletEntry({
    required this.id,
    required this.seq,
    required this.kind,
    required this.category,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;
  bool get isReversed => status == 'reversed';
}

/// One office's credit relationship with this rider.
class ClientWallet {
  final String walletId;
  final String officeId;
  final String officeName;
  final String? officeLogoUrl;
  final double balance;
  final double availableBalance;

  /// `frozen` blocks spending, never crediting — a refund can always reach a
  /// frozen wallet.
  final String status;
  final int entryCount;
  final DateTime? updatedAt;
  final List<ClientWalletEntry> entries;

  const ClientWallet({
    required this.walletId,
    required this.officeId,
    required this.officeName,
    required this.balance,
    required this.availableBalance,
    required this.status,
    required this.entryCount,
    required this.entries,
    this.officeLogoUrl,
    this.updatedAt,
  });

  bool get isFrozen => status == 'frozen';
  bool get hasBalance => balance > 0;
}

/// Everything the rider's wallet screen shows.
class ClientWalletSummary {
  /// Σ of every office balance. A convenience for the header only — it is not a
  /// spendable pot, and the screen says so.
  final double totalBalance;
  final List<ClientWallet> wallets;
  final DateTime generatedAt;

  const ClientWalletSummary({
    required this.totalBalance,
    required this.wallets,
    required this.generatedAt,
  });

  bool get isEmpty => wallets.isEmpty;
}

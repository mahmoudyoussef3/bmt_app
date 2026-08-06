import 'wallet_vocabulary.dart';

/// A customer's credit balance with ONE office.
///
/// Named `Wallet`, not `CustomerWallet`, deliberately (§3A.8): the database
/// column that pins ownership to a client is a CHECK, and relaxing it later must
/// not force a rename across every entity, repository, use case and test. The
/// Arabic UI label stays *محفظة العملاء* because in V1 every wallet does belong
/// to a customer — the user-facing name is a product decision, the code name an
/// architectural one, and they are allowed to differ.
class Wallet {
  /// `false` until the first entry is posted. A customer with no wallet row is
  /// not an error and not a special case: the balance is simply zero, and the
  /// wallet is created inside the transaction that first credits it.
  final bool exists;
  final String? id;
  final double balance;

  /// `balance − reserved`. Identical to [balance] in V1 (reserved is CHECK-pinned
  /// to zero), and read everywhere instead of [balance] so that enabling holds
  /// later changes no call site.
  final double availableBalance;
  final WalletStatus status;
  final String? frozenReason;
  final DateTime? frozenAt;
  final int entryCount;
  final double lifetimeCredited;
  final double lifetimeDebited;
  final int lastSeq;

  /// The head of the wallet's sha256 chain, hex encoded. Exported alongside a
  /// statement so an off-database copy exists that in-database edits cannot
  /// reach (§2.5).
  final String? headHash;
  final DateTime? updatedAt;

  const Wallet({
    required this.exists,
    required this.balance,
    required this.availableBalance,
    required this.status,
    this.id,
    this.frozenReason,
    this.frozenAt,
    this.entryCount = 0,
    this.lifetimeCredited = 0,
    this.lifetimeDebited = 0,
    this.lastSeq = 0,
    this.headHash,
    this.updatedAt,
  });

  const Wallet.empty()
    : exists = false,
      id = null,
      balance = 0,
      availableBalance = 0,
      status = WalletStatus.active,
      frozenReason = null,
      frozenAt = null,
      entryCount = 0,
      lifetimeCredited = 0,
      lifetimeDebited = 0,
      lastSeq = 0,
      headHash = null,
      updatedAt = null;

  bool get isFrozen => status == WalletStatus.frozen;
}

/// The customer a wallet belongs to. A separate type from the client app's
/// profile: the dashboard has no customer entity at all (§1.1), and this is the
/// office's view of one — identity plus the fact that they bought something here.
class WalletCustomer {
  final String id;
  final String fullName;
  final String phone;
  final String? status;
  final DateTime? createdAt;

  const WalletCustomer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.status,
    this.createdAt,
  });

  String get displayName => fullName.trim().isEmpty ? 'عميل بدون اسم' : fullName;
}

/// One row of the customer directory (surface 1).
class WalletDirectoryEntry {
  final String clientId;
  final String fullName;
  final String phone;
  final double balance;
  final WalletStatus walletStatus;
  final int entryCount;
  final DateTime? lastActivityAt;

  /// Refund requests waiting on a decision for this customer. Surfaced in the
  /// list, not only on the detail screen, so an operator scanning the directory
  /// can see where the queue actually is.
  final int pendingRefunds;

  const WalletDirectoryEntry({
    required this.clientId,
    required this.fullName,
    required this.phone,
    required this.balance,
    required this.walletStatus,
    required this.entryCount,
    required this.pendingRefunds,
    this.lastActivityAt,
  });

  String get displayName => fullName.trim().isEmpty ? 'عميل بدون اسم' : fullName;
}

class WalletDirectoryPage {
  final int total;
  final List<WalletDirectoryEntry> rows;

  const WalletDirectoryPage({required this.total, required this.rows});

  const WalletDirectoryPage.empty() : total = 0, rows = const [];
}

/// The office's own limits, as configured data rather than shipped constants.
///
/// Display and step-up only: every cap here is enforced server-side inside
/// `wallet_post_entry`, and this copy exists so a dialog can *say* what the
/// limit is instead of letting the operator discover it by being refused.
class WalletPolicy {
  final double maxSingleCredit;
  final double maxSingleDebit;
  final double maxOperatorDailyPromo;

  /// Above this, the dialog asks the operator to re-type the amount before it
  /// will submit (§9, §11). Null means the office has not asked for step-up, in
  /// which case a debit's double confirmation is the only extra ceremony.
  final double? requireSecondApprovalAbove;

  /// Daily caps are evaluated here, not in the server's UTC and not on the
  /// operator's device (§14 case 14).
  final String timezone;

  const WalletPolicy({
    this.maxSingleCredit = 1000,
    this.maxSingleDebit = 1000,
    this.maxOperatorDailyPromo = 2000,
    this.requireSecondApprovalAbove,
    this.timezone = 'Africa/Cairo',
  });

  double capFor({required bool credit}) =>
      credit ? maxSingleCredit : maxSingleDebit;

  bool needsStepUp(double amount) {
    final threshold = requireSecondApprovalAbove;
    return threshold != null && amount > threshold;
  }
}

/// The office-wide header strip (§8.2), and the source of Finance's LIABILITY
/// figure (§7.1).
class WalletOverview {
  /// Σ wallets.balance — money the office holds and owes back as service. A
  /// liability, not revenue and not cash.
  final double outstandingBalance;
  final int walletCount;
  final int fundedWalletCount;
  final int frozenCount;

  /// Promotional cost: reported separately because it creates a liability with
  /// no cash received. Subtracting it from revenue would understate what the
  /// office actually sold (§7.1).
  final double cashbackTotal;
  final double creditTotal;
  final double debitTotal;

  /// Read from `refund_requests`, NOT from the ledger: a refund to InstaPay
  /// never posts a wallet row (§2.3).
  final double refundTotal;
  final double refundWalletTotal;

  final int pendingRefundCount;
  final double pendingRefundAmount;
  final WalletPolicy policy;
  final DateTime generatedAt;

  const WalletOverview({
    required this.outstandingBalance,
    required this.walletCount,
    required this.fundedWalletCount,
    required this.frozenCount,
    required this.cashbackTotal,
    required this.creditTotal,
    required this.debitTotal,
    required this.refundTotal,
    required this.refundWalletTotal,
    required this.pendingRefundCount,
    required this.pendingRefundAmount,
    required this.generatedAt,
    this.policy = const WalletPolicy(),
  });

  /// Everything the office has given away as incentive — the marketing and
  /// compensation line Finance reports beside revenue rather than inside it.
  double get promotionalCost => cashbackTotal + creditTotal;
}

/// The result of recomputing a wallet's sequence and hash chain (§2.5).
class WalletChainVerification {
  final bool verified;

  /// `sequence_gap` | `chain_break` | `hash_mismatch` | `balance_drift` |
  /// `head_mismatch`, or null when the chain is intact.
  final String? fault;
  final int? divergentSeq;
  final int entries;
  final double ledgerBalance;
  final double cachedBalance;
  final String? headHash;

  const WalletChainVerification({
    required this.verified,
    required this.entries,
    required this.ledgerBalance,
    required this.cachedBalance,
    this.fault,
    this.divergentSeq,
    this.headHash,
  });

  String get faultLabel => switch (fault) {
    'sequence_gap' => 'فجوة في تسلسل العمليات — سجل محذوف',
    'chain_break' => 'انقطاع في سلسلة التحقق',
    'hash_mismatch' => 'بصمة عملية غير مطابقة — تم تعديل سجل',
    'balance_drift' => 'الرصيد لا يساوي مجموع الحركات',
    'head_mismatch' => 'بصمة نهاية السلسلة غير مطابقة',
    _ => 'غير معروف',
  };
}

/// The three-statement money model, and the identity that proves it.
///
/// ## Why one number was not enough
///
/// The office's earlier model computed a single "net revenue" and treated a
/// wallet balance as if it were either revenue or cash. Trace three events
/// through that:
///
/// ```
/// 1. Customer books, pays 300 cash          → gross 300
/// 2. Trip cancelled, 300 refunded to wallet → refunds 300, net 0
/// 3. Customer rebooks, pays with the 300    → excluded from gross, net still 0
/// ```
///
/// The office ran two trips, kept 300 EGP, and the report said it earned
/// **nothing**. The error is conflating **cash** with **revenue**. A wallet
/// balance is neither — it is a **liability**: money the office holds and owes
/// back as service.
///
/// The fix is to stop computing one number and compute three, each independently
/// simple:
///
/// ```
/// REVENUE   (accrual)  = Σ fare of sold bookings      − Σ refunds granted (any destination)
/// CASH      (treasury) = Σ external tender received   − Σ refunds settled outside the wallet
/// LIABILITY            = Σ wallet balances
/// ```
///
/// Revenue is keyed on the **fare** and is indifferent to how it was tendered.
/// Cash is keyed on **tender** and is indifferent to what was sold. That
/// separation is what makes double-counting structurally impossible rather than
/// a rule someone has to remember.
library;

import 'finance_entities.dart';

/// What a wallet movement did to the balance. Mirrors the ledger's closed `kind`
/// axis; redeclared here rather than imported so the Finance domain does not
/// depend on the wallet module.
enum WalletMovementKind {
  refund('refund'),
  cashback('cashback'),
  manualCredit('manual_credit'),
  manualDebit('manual_debit'),
  walletSpend('wallet_spend'),
  walletTopup('wallet_topup'),
  reversal('reversal');

  const WalletMovementKind(this.dbValue);

  final String dbValue;

  static WalletMovementKind fromDb(String value) =>
      WalletMovementKind.values.firstWhere(
        (kind) => kind.dbValue == value,
        orElse: () => WalletMovementKind.manualCredit,
      );
}

/// One posted wallet-ledger entry, as Finance needs it: when, what kind, and the
/// signed amount. Everything else on the row is the wallet module's business.
class WalletMovement {
  final DateTime date;
  final WalletMovementKind kind;

  /// Signed: credits positive, debits negative. Σ amount is exactly ΔLIABILITY.
  final double amount;

  const WalletMovement({
    required this.date,
    required this.kind,
    required this.amount,
  });

  /// Money given away as incentive rather than owed back for a service failure.
  /// A clawback (`manualDebit`) is the same expense with the opposite sign,
  /// which is why promotional cost is reported net.
  bool get isPromotional =>
      kind == WalletMovementKind.cashback ||
      kind == WalletMovementKind.manualCredit ||
      kind == WalletMovementKind.manualDebit;
}

/// One **settled** refund, whatever its destination.
///
/// Read from `refund_requests` and not from the wallet ledger: a refund to
/// InstaPay never posts a wallet row, so a ledger-derived refund total omits
/// exactly the amounts most likely to be disputed.
class SettledRefund {
  final DateTime settledAt;
  final double amount;

  /// True when the money went back into the customer's wallet — the only
  /// destination that costs the office no cash.
  final bool toWallet;

  const SettledRefund({
    required this.settledAt,
    required this.amount,
    required this.toWallet,
  });
}

/// The wallet-side facts Finance reads. Two queries, no aggregation server-side:
/// the window is chosen on the client, so the arithmetic has to be too.
class WalletFinancePosition {
  /// Σ wallet balances **right now**. Window-scoped figures are back-computed
  /// from [movements] rather than fetched per period — the ledger is complete
  /// and ordered, so every historical position is derivable from the present one.
  final double currentLiability;
  final List<WalletMovement> movements;
  final List<SettledRefund> refunds;

  const WalletFinancePosition({
    required this.currentLiability,
    required this.movements,
    required this.refunds,
  });

  const WalletFinancePosition.empty()
    : currentLiability = 0,
      movements = const [],
      refunds = const [];

  bool get isEmpty => movements.isEmpty && refunds.isEmpty && currentLiability == 0;
}

/// The three statements over one reporting window, plus the control identity.
class FinanceMoneyStatements {
  /// Accrual. What the office **sold**, net of everything it gave back.
  final double revenue;

  /// Treasury. What the office actually **holds**, net of what it paid out.
  final double cash;

  /// What the office **owes back as service** at the close of the window.
  final double liabilityEnd;

  /// The same at the open of the window; the difference is what the identity
  /// balances against.
  final double liabilityStart;

  /// Marketing and compensation, **net of clawbacks**. Reported beside revenue,
  /// never subtracted from it: it creates a liability with no cash received, and
  /// netting it off would understate what the office actually sold.
  final double promotionalCost;

  /// External tender received in the window.
  final double cashIn;

  /// Refunds settled in cash, by bank transfer or back to the original method.
  final double cashOut;

  /// Every refund settled in the window, any destination. This is the figure
  /// revenue is reduced by.
  final double refundsTotal;

  /// The part of [refundsTotal] that went to a wallet and therefore cost no cash.
  final double refundsToWallet;

  const FinanceMoneyStatements({
    required this.revenue,
    required this.cash,
    required this.liabilityStart,
    required this.liabilityEnd,
    required this.promotionalCost,
    required this.cashIn,
    required this.cashOut,
    required this.refundsTotal,
    required this.refundsToWallet,
  });

  const FinanceMoneyStatements.empty()
    : revenue = 0,
      cash = 0,
      liabilityStart = 0,
      liabilityEnd = 0,
      promotionalCost = 0,
      cashIn = 0,
      cashOut = 0,
      refundsTotal = 0,
      refundsToWallet = 0;

  /// Builds the three statements for [range].
  ///
  /// [soldFare] is Σ `payment_amount` of bookings that reached a sold state in
  /// the window — the **fare**, not the tender. That distinction is the whole
  /// correction: it is what makes a wallet-paid rebooking count as revenue.
  factory FinanceMoneyStatements.from({
    required double soldFare,
    required double externalTender,
    required WalletFinancePosition wallet,
    required FinanceDateRange range,
  }) {
    var refundsTotal = 0.0;
    var refundsToWallet = 0.0;
    for (final refund in wallet.refunds) {
      if (!range.contains(refund.settledAt)) continue;
      refundsTotal += refund.amount;
      if (refund.toWallet) refundsToWallet += refund.amount;
    }

    var deltaLiability = 0.0;
    var promotional = 0.0;
    var afterWindow = 0.0;
    for (final movement in wallet.movements) {
      
      if (movement.date.isAfter(range.end)) {
        afterWindow += movement.amount;
        continue;
      }
      if (!range.contains(movement.date)) continue;
      deltaLiability += movement.amount;
      if (movement.isPromotional) promotional += movement.amount;
    }

    final liabilityEnd = wallet.currentLiability - afterWindow;

    return FinanceMoneyStatements(
      revenue: soldFare - refundsTotal,
      cash: externalTender - (refundsTotal - refundsToWallet),
      liabilityStart: liabilityEnd - deltaLiability,
      liabilityEnd: liabilityEnd,
      promotionalCost: promotional,
      cashIn: externalTender,
      cashOut: refundsTotal - refundsToWallet,
      refundsTotal: refundsTotal,
      refundsToWallet: refundsToWallet,
    );
  }

  double get deltaLiability => liabilityEnd - liabilityStart;

  /// What the office kept after paying for its own incentives. Reported as a
  /// second line, not as *the* revenue figure.
  double get contributionAfterIncentives => revenue - promotionalCost;

  /// ```
  /// CASH_in − CASH_out  =  REVENUE − PROMOTIONAL_COST + ΔLIABILITY
  /// ```
  ///
  /// Asserted on every load. If it does not balance to the piastre, something is
  /// broken and the module says so rather than displaying a plausible wrong
  /// number.
  double get identityGap =>
      (cashIn - cashOut) - (revenue - promotionalCost + deltaLiability);

  /// One piastre of tolerance, for floating-point noise only — not for a real
  /// discrepancy, which at this scale is always larger.
  bool get identityHolds => identityGap.abs() < 0.01;
}

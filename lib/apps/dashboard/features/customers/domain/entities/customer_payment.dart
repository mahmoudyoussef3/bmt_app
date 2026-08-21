/// One payment this customer made to this office.
///
/// The processor columns on `booking_payments` — `gateway_response`,
/// `gateway_transaction_id`, `gateway_order_id` — are deliberately absent from
/// this entity and from the RPC that fills it. `gateway_response` is the raw
/// processor payload and can carry instrument details and tokens; none of it
/// answers a question an operator asks, and a read path that never selects it
/// cannot leak it.
class CustomerPayment {
  final String id;
  final String? bookingId;
  final String? bookingNumber;
  final String? route;
  final DateTime? tripDate;

  /// `instapay` | `vodafone_cash` | `cash` | `card` | `bank_transfer`.
  final String method;

  final double amount;
  final String currency;

  /// `submitted` | `approved` | `cancelled` — the review state of the receipt.
  final String status;

  /// The customer's own transfer reference, when they supplied one. This is a
  /// reference *they* quote, not an instrument identifier.
  final String? paymentReference;

  final DateTime? submittedAt;
  final DateTime? paidAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const CustomerPayment({
    required this.id,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    this.bookingId,
    this.bookingNumber,
    this.route,
    this.tripDate,
    this.paymentReference,
    this.submittedAt,
    this.paidAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  bool get isApproved => status == 'approved';
}

/// The customer's wallet with this office, when one exists.
class CustomerWallet {
  final double balance;
  final double? availableBalance;
  final double? reservedBalance;
  final String currency;
  final String status;
  final double lifetimeCredited;
  final double lifetimeDebited;

  const CustomerWallet({
    required this.balance,
    required this.currency,
    required this.status,
    this.availableBalance,
    this.reservedBalance,
    this.lifetimeCredited = 0,
    this.lifetimeDebited = 0,
  });

  bool get isFrozen => status == 'frozen';
}

/// One wallet movement. Mirrors محفظة العملاء's vocabulary rather than
/// restating it: `kind` is the database's own value, and the label for it is
/// resolved in the presentation layer beside every other status label.
class CustomerWalletEntry {
  final String id;
  final String kind;
  final String category;
  final double amount;
  final String currency;
  final double balanceAfter;
  final String reason;
  final DateTime createdAt;
  final String performedByName;

  const CustomerWalletEntry({
    required this.id,
    required this.kind,
    required this.category,
    required this.amount,
    required this.currency,
    required this.balanceAfter,
    required this.reason,
    required this.createdAt,
    required this.performedByName,
  });

  /// Credits add to the balance. `refund` and `cashback` and `manual_credit`
  /// are the three that do; the debit kinds subtract.
  bool get isCredit => !kind.contains('debit');
}

/// The المدفوعات tab in one round trip: a page of payments, the office-wide
/// total the customer has paid, and the wallet position beside it.
class CustomerPaymentsPage {
  final int total;
  final List<CustomerPayment> rows;
  final double totalApproved;
  final CustomerWallet? wallet;
  final List<CustomerWalletEntry> walletTransactions;

  const CustomerPaymentsPage({
    required this.total,
    required this.rows,
    this.totalApproved = 0,
    this.wallet,
    this.walletTransactions = const [],
  });

  const CustomerPaymentsPage.empty()
    : total = 0,
      rows = const [],
      totalApproved = 0,
      wallet = null,
      walletTransactions = const [];

  bool get hasWallet => wallet != null;
}

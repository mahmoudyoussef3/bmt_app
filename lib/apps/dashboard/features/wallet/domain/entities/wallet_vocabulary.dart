/// The wallet module's shared vocabulary: the three transaction axes, the
/// category allowlist, wallet and refund states.
///
/// Every value here mirrors a database CHECK or the `wallet_category_allowed`
/// function. The database is the authority — this file exists so the UI can
/// label and group without a round trip, and so an invalid combination is
/// unbuildable in Dart before it is unwritable in SQL.
library;

/// **What happened to the balance.** Closed axis — the accounting depends on it
/// (§2.4). Adding a value here is a database CHECK migration, and that friction
/// is deliberate: a new *balance effect* forces a decision about accounting
/// treatment, while a new business *reason* is only a [WalletCategory].
enum WalletKind {
  refund('refund', 'استرداد', true),
  cashback('cashback', 'كاش باك', true),
  manualCredit('manual_credit', 'إضافة رصيد', true),
  manualDebit('manual_debit', 'خصم رصيد', false),
  walletSpend('wallet_spend', 'دفع من المحفظة', false),
  walletTopup('wallet_topup', 'شحن المحفظة', true),
  // Direction mirrors whatever it reverses, so `isCredit` is not meaningful
  // here; read the sign of the amount instead.
  reversal('reversal', 'عملية عكسية', true);

  const WalletKind(this.dbValue, this.label, this.isCredit);

  final String dbValue;
  final String label;
  final bool isCredit;

  static WalletKind fromDb(String value) => WalletKind.values.firstWhere(
    (kind) => kind.dbValue == value,
    orElse: () => WalletKind.manualCredit,
  );

  /// The kinds V1 actually emits. `walletSpend` and `walletTopup` are reserved
  /// for V2 and must not appear in a filter chip bar that would only ever return
  /// nothing.
  static const List<WalletKind> active = [
    WalletKind.refund,
    WalletKind.cashback,
    WalletKind.manualCredit,
    WalletKind.manualDebit,
    WalletKind.reversal,
  ];
}

/// **Why.** Open axis — the business adds reasons forever, and each one is a row
/// in the allowlist below rather than a new [WalletKind].
class WalletCategory {
  final String code;
  final String label;

  const WalletCategory(this.code, this.label);
}

/// The per-kind allowlist, mirroring `public.wallet_category_allowed`.
///
/// Kept in this order because it is the order the dialogs offer: the most
/// commonly chosen reason first, so the default selection is usually right.
abstract final class WalletCategories {
  const WalletCategories._();

  static const refund = [
    WalletCategory('trip_cancelled', 'إلغاء الرحلة'),
    WalletCategory('booking_cancelled', 'إلغاء الحجز'),
    WalletCategory('driver_unavailable', 'عدم توفر سائق'),
    WalletCategory('office_error', 'خطأ من المكتب'),
    WalletCategory('duplicate_payment', 'دفع مكرر'),
    WalletCategory('service_failure', 'خلل في الخدمة'),
    WalletCategory('other', 'سبب آخر'),
  ];

  static const cashback = [
    WalletCategory('promotion', 'عرض ترويجي'),
    WalletCategory('compensation', 'تعويض'),
    WalletCategory('loyalty', 'مكافأة ولاء'),
    WalletCategory('retention', 'استبقاء عميل'),
    WalletCategory('marketing_campaign', 'حملة تسويقية'),
    WalletCategory('referral', 'مكافأة إحالة'),
  ];

  static const manualCredit = [
    WalletCategory('support_adjustment', 'تسوية خدمة عملاء'),
    WalletCategory('goodwill', 'بادرة حسن نية'),
    WalletCategory('correction', 'تصحيح'),
    WalletCategory('migration', 'ترحيل بيانات'),
  ];

  static const manualDebit = [
    WalletCategory('correction', 'تصحيح'),
    WalletCategory('wrong_cashback', 'كاش باك خاطئ'),
    WalletCategory('accounting_adjustment', 'تسوية محاسبية'),
    WalletCategory('clawback', 'استرجاع مكافأة'),
  ];

  static const reversal = [
    WalletCategory('operator_error', 'خطأ من المشغّل'),
    WalletCategory('duplicate', 'عملية مكررة'),
    WalletCategory('fraud', 'اشتباه احتيال'),
    WalletCategory('dispute', 'نزاع'),
  ];

  static List<WalletCategory> forKind(WalletKind kind) => switch (kind) {
    WalletKind.refund => refund,
    WalletKind.cashback => cashback,
    WalletKind.manualCredit => manualCredit,
    WalletKind.manualDebit => manualDebit,
    WalletKind.reversal => reversal,
    // V2 kinds carry their own small allowlists server-side; nothing in the
    // dashboard offers them, so there is no picker to fill.
    WalletKind.walletSpend || WalletKind.walletTopup => const [],
  };

  /// Human label for a stored category code, whatever kind it came from.
  /// Falls back to the raw code so an unknown value from a newer server build
  /// still renders as *something* rather than a blank cell.
  static String labelOf(String code) {
    for (final list in [refund, cashback, manualCredit, manualDebit, reversal]) {
      for (final category in list) {
        if (category.code == code) return category.label;
      }
    }
    return code;
  }
}

/// **Who drove it.** Closed, small.
enum WalletSource {
  dashboard('dashboard', 'لوحة التحكم'),
  client('client', 'تطبيق العميل'),
  system('system', 'النظام'),
  migration('migration', 'ترحيل بيانات');

  const WalletSource(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static WalletSource fromDb(String value) => WalletSource.values.firstWhere(
    (source) => source.dbValue == value,
    orElse: () => WalletSource.dashboard,
  );
}

/// A ledger entry is `posted` until a reversal closes it. Nothing else is a
/// legal transition, and nothing is ever deleted.
enum WalletEntryStatus {
  posted('posted', 'مُسجَّلة'),
  reversed('reversed', 'معكوسة');

  const WalletEntryStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static WalletEntryStatus fromDb(String value) =>
      value == 'reversed' ? WalletEntryStatus.reversed : WalletEntryStatus.posted;
}

/// A frozen wallet still accepts credits — you must always be able to refund
/// someone — but refuses debits. Freezing is a fraud hold, not a punishment.
enum WalletStatus {
  active('active', 'نشطة'),
  frozen('frozen', 'مجمّدة');

  const WalletStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static WalletStatus fromDb(String value) =>
      value == 'frozen' ? WalletStatus.frozen : WalletStatus.active;
}

enum RefundStatus {
  pending('pending', 'قيد المراجعة'),
  approved('approved', 'معتمد'),
  settled('settled', 'منفّذ'),
  rejected('rejected', 'مرفوض'),
  failed('failed', 'فشل التنفيذ'),
  cancelled('cancelled', 'ملغي');

  const RefundStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static RefundStatus fromDb(String value) => RefundStatus.values.firstWhere(
    (status) => status.dbValue == value,
    orElse: () => RefundStatus.pending,
  );

  /// Still awaiting or mid-decision — the rows the queue exists to clear.
  bool get isOpen => this == RefundStatus.pending || this == RefundStatus.approved;
}

/// Where the money actually went. Only [wallet] posts a ledger entry; all four
/// produce a refund record and all four reduce revenue (§9.2).
enum RefundSettlement {
  wallet('wallet', 'إلى المحفظة'),
  originalMethod('original_method', 'بنفس وسيلة الدفع'),
  cash('cash', 'نقدًا'),
  bankTransfer('bank_transfer', 'تحويل بنكي');

  const RefundSettlement(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static RefundSettlement fromDb(String? value) =>
      RefundSettlement.values.firstWhere(
        (method) => method.dbValue == value,
        orElse: () => RefundSettlement.wallet,
      );
}

/// One thing that actually happened, at a timestamp the database recorded.
///
/// The feed is a union of eleven real columns — a booking's `created_at`, a
/// receipt's `submitted_at`, the moment a passenger was marked aboard. Nothing
/// is inferred from an absence and nothing is synthesised: if the database did
/// not record when something happened, it does not appear here.
enum CustomerActivityKind {
  bookingCreated('booking_created', 'تم إنشاء حجز'),
  bookingCancelled('booking_cancelled', 'تم إلغاء الحجز'),
  paymentSubmitted('payment_submitted', 'تم رفع إيصال الدفع'),
  paymentApproved('payment_approved', 'تم تأكيد الدفع'),
  boarded('boarded', 'تم الصعود إلى الرحلة'),
  noShow('no_show', 'لم يحضر الرحلة'),
  subscriptionCreated('subscription_created', 'تم إنشاء اشتراك'),
  walletCashback('wallet_cashback', 'كاش باك على المحفظة'),
  walletCredit('wallet_manual_credit', 'إضافة رصيد للمحفظة'),
  walletDebit('wallet_manual_debit', 'خصم من المحفظة'),
  walletRefund('wallet_refund', 'استرداد إلى المحفظة'),
  reviewSubmitted('review_submitted', 'أضاف تقييماً'),
  ticketOpened('ticket_opened', 'فتح شكوى'),
  refundSettled('refund_settled', 'تم صرف استرداد'),

  /// A `wallet_*` kind the app has not been taught yet. Rendering the raw wire
  /// value would put `wallet_promo_credit` in front of an operator; this says
  /// what it is at the level the app is sure of.
  unknown('', 'حركة على الحساب');

  const CustomerActivityKind(this.wire, this.label);

  final String wire;
  final String label;

  static CustomerActivityKind fromWire(String value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => CustomerActivityKind.unknown,
  );
}

class CustomerActivityEvent {
  final CustomerActivityKind kind;
  final DateTime at;

  /// What it happened to — a route, a package name, a payment method.
  final String? subject;

  /// A booking number, a seat, a category. Secondary, and often null.
  final String? reference;

  /// Present only on money events.
  final double? amount;

  const CustomerActivityEvent({
    required this.kind,
    required this.at,
    this.subject,
    this.reference,
    this.amount,
  });
}

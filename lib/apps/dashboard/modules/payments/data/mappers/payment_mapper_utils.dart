import '../../domain/entities/finance_payment.dart';

FinancePaymentMethod mapFinancePaymentMethod(String value) {
  return switch (value.toLowerCase()) {
    'card' || 'credit_card' || 'debit_card' => FinancePaymentMethod.card,
    'wallet' ||
    'e_wallet' ||
    'mobile_wallet' ||
    'wallet_balance' => FinancePaymentMethod.wallet,
    'bank_transfer' ||
    'banktransfer' ||
    'instapay' => FinancePaymentMethod.bankTransfer,
    'cash' || 'cash_on_boarding' => FinancePaymentMethod.cash,
    _ => FinancePaymentMethod.bankTransfer,
  };
}

String paymentReceiptLabel(FinancePaymentMethod method) => switch (method) {
  FinancePaymentMethod.card => 'إيصال دفع بطاقة',
  FinancePaymentMethod.wallet => 'لقطة شاشة محفظة',
  FinancePaymentMethod.bankTransfer => 'إيصال تحويل بنكي',
  FinancePaymentMethod.cash => 'إيصال نقدي',
};

String paymentReceiptMeta(String? url) =>
    url != null && url.isNotEmpty ? 'صورة إيصال مرفوعة' : 'لم يتم رفع إيصال';

String formatPaymentDate(String? iso) {
  if (iso == null) return '';
  try {
    final date = DateTime.parse(iso).toLocal();
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) return 'اليوم ${_time(date)}';
    if (difference.inDays == 1) return 'أمس ${_time(date)}';
    return '${date.day}/${date.month}/${date.year}';
  } catch (_) {
    return iso;
  }
}

String _time(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'ص' : 'م';
  return '$hour:$minute $period';
}

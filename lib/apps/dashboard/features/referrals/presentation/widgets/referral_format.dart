import 'package:intl/intl.dart' as intl;

/// Arabic-digit + label helpers shared across the referral admin tabs,
/// matching the dashboard's existing Arabic formatting convention.
String referralArDigits(String text) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var out = text;
  for (var i = 0; i < western.length; i++) {
    out = out.replaceAll(western[i], eastern[i]);
  }
  return out;
}

String referralArNum(num value) {
  final text = value is int || value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return referralArDigits(text);
}

String referralArPercent(num value) => '${referralArNum(value)}٪';

String referralArDate(DateTime? value) {
  if (value == null) return '—';
  return referralArDigits(intl.DateFormat('yyyy/MM/dd').format(value));
}

String referralRewardTypeLabel(String type) => switch (type) {
  'points' => 'نقاط',
  'wallet' => 'رصيد المحفظة',
  'coupon' => 'كوبون خصم',
  'loyalty' => 'نقاط ولاء',
  _ => type,
};

/// Unit suffix shown next to a reward amount.
String referralRewardUnit(String type, String currency) =>
    type == 'wallet' || type == 'coupon' ? currency : 'نقطة';

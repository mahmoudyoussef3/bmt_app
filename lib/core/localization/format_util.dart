import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class FormatUtil {
  const FormatUtil._();

  /// Formats currency based on the provided BuildContext's locale.
  ///
  /// Produces `EGP 100` / `ج.م ١٠٠`-style output: symbol, space, amount. This
  /// deliberately matches `moneyLabel` in the client's `client_money.dart`,
  /// which prices trip and office cards without a [BuildContext] — a rider who
  /// browses a fare and then opens checkout must not see the same number
  /// written two different ways.
  ///
  /// Whole amounts drop their `.00`: fares here are whole pounds far more often
  /// than not, and a forced `EGP 100.00` reads as machine output next to the
  /// `EGP 100` on the card the rider just tapped.
  static String currency(
    BuildContext context,
    num value, {
    String symbol = 'EGP',
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    final formatter = NumberFormat.decimalPattern(
      isArabic ? 'ar_EG' : 'en_US',
    );
    final isWhole = value == value.roundToDouble();
    formatter
      ..minimumFractionDigits = isWhole ? 0 : 2
      ..maximumFractionDigits = isWhole ? 0 : 2;
    return '${isArabic ? 'ج.م' : symbol} ${formatter.format(value)}';
  }

  /// Formats date based on the provided BuildContext's locale.
  static String date(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale == 'ar' ? 'ar' : 'en').format(date);
  }

  /// Formats time based on the provided BuildContext's locale.
  static String time(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.jm(locale == 'ar' ? 'ar' : 'en').format(time);
  }

  /// Formats a number with appropriate thousands separators.
  static String number(BuildContext context, num value) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.decimalPattern(
      locale == 'ar' ? 'ar_EG' : 'en_US',
    ).format(value);
  }
}

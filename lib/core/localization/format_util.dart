import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class FormatUtil {
  const FormatUtil._();

  /// Formats currency based on the provided BuildContext's locale.
  static String currency(
    BuildContext context,
    num value, {
    String symbol = 'EGP',
  }) {
    final locale = Localizations.localeOf(context).languageCode;
    // Uses standard Arabic numerals (123) for standard formatting unless Eastern Arabic (١٢٣) is specifically requested later.
    final formatter = NumberFormat.currency(
      locale: locale == 'ar' ? 'ar_EG' : 'en_US',
      symbol: locale == 'ar' ? 'ج.م' : symbol,
      decimalDigits: 2,
    );
    return formatter.format(value);
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

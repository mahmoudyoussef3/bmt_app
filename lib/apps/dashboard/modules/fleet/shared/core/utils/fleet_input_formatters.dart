import 'package:flutter/services.dart';

class FleetInputFormatters {
  const FleetInputFormatters._();

  static final digitsOnly = FilteringTextInputFormatter.digitsOnly;

  static final egyptianPhone = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(11),
  ];

  static final nationalId = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(14),
  ];

  static final year = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(4),
  ];

  static final capacity = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(3),
  ];

  static final money = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    _SingleDecimalPointFormatter(),
  ];

  static final signedDecimal = [
    FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
    _SignedDecimalFormatter(),
  ];
}

class _SingleDecimalPointFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if ('.'.allMatches(text).length > 1) return oldValue;
    final parts = text.split('.');
    if (parts.length == 2 && parts.last.length > 2) return oldValue;
    return newValue;
  }
}

class _SignedDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if ('-'.allMatches(text).length > 1) return oldValue;
    if (text.contains('-') && !text.startsWith('-')) return oldValue;
    if ('.'.allMatches(text).length > 1) return oldValue;
    return newValue;
  }
}

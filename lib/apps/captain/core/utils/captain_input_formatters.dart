import 'package:flutter/services.dart';

import 'captain_digits.dart';

/// Keeps a field to ASCII digits, whichever numerals the captain actually
/// types.
///
/// [FilteringTextInputFormatter.digitsOnly] cannot be used for this: it matches
/// ASCII only, so an Arabic keypad's `٠١٢` is "not a digit" and the field stays
/// empty while the captain keeps pressing keys. This normalizes first, then
/// filters, then rebuilds the caret from how many digits survived ahead of it —
/// so pasting `+20 100 123 4567` lands the caret in the right place instead of
/// at the start.
class CaptainDigitsInputFormatter extends TextInputFormatter {
  const CaptainDigitsInputFormatter({this.maxLength});

  /// Hard cap on the digit count. Enforced here rather than through
  /// `TextField.maxLength` so no counter is ever rendered under the field.
  final int? maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = CaptainDigits.only(newValue.text);
    final cap = maxLength;
    if (cap != null && digits.length > cap) digits = digits.substring(0, cap);
    if (digits == newValue.text) return newValue;

    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final kept = CaptainDigits.only(newValue.text.substring(0, caret)).length;

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: kept.clamp(0, digits.length)),
    );
  }
}

/// Upper-cases as the captain types — office codes are printed and handed over
/// in capitals, and the backend compares them that way.
class CaptainUpperCaseInputFormatter extends TextInputFormatter {
  const CaptainUpperCaseInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return TextEditingValue(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

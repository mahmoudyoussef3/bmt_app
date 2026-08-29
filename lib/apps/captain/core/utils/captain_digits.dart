/// Digit handling for the captain's forms.
///
/// An Egyptian phone keypad prints `٠١٢٣٤٥٦٧٨٩`, and an Arabic keyboard types
/// them. Dart's `\d` and [FilteringTextInputFormatter.digitsOnly] are both
/// ASCII-only, so a number typed the way it is *printed* is not a number as far
/// as either of them is concerned — the field would silently swallow every
/// keystroke. Everything numeric the captain types therefore passes through
/// [normalize] first.
class CaptainDigits {
  const CaptainDigits._();

  /// Rewrites Arabic-Indic (`٠..٩`) and Extended Arabic-Indic (`۰..۹`) digits
  /// as ASCII, leaving every other rune untouched.
  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// The ASCII digits of [value] and nothing else — spaces, dashes and the
  /// `+20` a captain may paste in from a contact card all fall away.
  static String only(String value) =>
      normalize(value).replaceAll(RegExp(r'[^0-9]'), '');
}

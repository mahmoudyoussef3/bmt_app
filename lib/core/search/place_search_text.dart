
abstract final class PlaceSearchText {

  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);

      if (rune >= 0x064B && rune <= 0x0652) continue;
      if (rune == 0x0640) continue;
      buffer.write(switch (char) {
        'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
        'ة' => 'ه',
        'ى' => 'ي',
        'ؤ' => 'و',
        'ئ' => 'ي',
        'گ' => 'ك',
        'پ' => 'ب',
        'چ' => 'ج',
        'ڤ' => 'ف',
        'é' || 'è' || 'ê' || 'ë' => 'e',
        'á' || 'à' || 'â' || 'ä' => 'a',
        'í' || 'ì' || 'î' || 'ï' => 'i',
        'ó' || 'ò' || 'ô' || 'ö' => 'o',
        'ú' || 'ù' || 'û' || 'ü' => 'u',
        _ =>
          rune >= 0x0660 && rune <= 0x0669
              ? String.fromCharCode(rune - 0x0660 + 0x30)
              : char,
      });
    }

    var text = buffer.toString().replaceAll(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
      ' ',
    );
    text = text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(_stripArticle)
        .where((word) => word.isNotEmpty)
        .join(' ');
    return text;
  }


  static bool containsNormalized(String haystack, String needle) {
    if (needle.isEmpty) return true;
    if (haystack.isEmpty) return false;
    return normalize(haystack).contains(needle);
  }

  static String _stripArticle(String word) {
    if (word.length > 3 && word.startsWith('ال')) return word.substring(2);
    if (word == 'el' || word == 'al') return '';
    return word;
  }
}

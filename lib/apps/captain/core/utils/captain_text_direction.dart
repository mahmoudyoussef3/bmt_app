import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

class CaptainTextDirection {
  const CaptainTextDirection._();

  static TextDirection ofIdentifier(String value) {
    return Bidi.detectRtlDirectionality(value)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

import 'package:flutter/widgets.dart';
// intl exports a TextDirection of its own, which would shadow Flutter's.
import 'package:intl/intl.dart' show Bidi;

/// Direction handling for values that are *data*, not prose.
class CaptainTextDirection {
  const CaptainTextDirection._();

  /// The direction an identifier should be laid out in, decided by the
  /// identifier itself rather than by the screen around it.
  ///
  /// The app runs RTL, so an inherited direction reorders the runs inside a
  /// mixed string: a latin plate `ABC 1234` renders as `1234 ABC`. Forcing LTR
  /// instead just moves the bug — this fleet's plates are Egyptian, and
  /// `ط ن ج 4821` under LTR reorders the other way. Neither hardcoded direction
  /// is right for both, so the value's first strong character picks, which is
  /// the same first-strong rule Unicode bidi itself uses.
  ///
  /// Use for plates, phone numbers, licence and employee codes. Prose must
  /// inherit the ambient direction instead — this would mis-handle a sentence
  /// that merely opens with a latin word.
  static TextDirection ofIdentifier(String value) {
    return Bidi.detectRtlDirectionality(value)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

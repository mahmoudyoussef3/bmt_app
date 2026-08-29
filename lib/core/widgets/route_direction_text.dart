import 'package:flutter/widgets.dart';

/// U+2068 FIRST STRONG ISOLATE — opens a run whose direction is decided by its
/// own first strong character, and which the surrounding text then treats as a
/// single neutral object.
const String _isolate = '\u2068';

/// U+2069 POP DIRECTIONAL ISOLATE — closes the run opened by [_isolate].
const String _popIsolate = '\u2069';

/// U+2190 LEFTWARDS ARROW / U+2192 RIGHTWARDS ARROW.
const String _leftArrow = '\u2190';
const String _rightArrow = '\u2192';

/// Composes `origin → destination` so it still means *origin → destination*
/// after the bidi algorithm has laid it out.
///
/// A hand-rolled `'$origin → $destination'` announces the journey backwards
/// about half the time, and which half depends on the *script of the place
/// names* rather than on anything the code can see:
///
/// - two Arabic names in an RTL app put the origin on the right (correct) but
///   leave the rightwards arrow pointing back at it;
/// - two Latin names — what the geocoder returns for most Egyptian places
///   ("New Cairo", "Zefta") — make the whole line resolve LTR under UAX#9 rule
///   N1, so an `←` variant then points at the origin instead;
/// - one of each (`New Cairo → شبرا بخوم`) renders as `شبرا بخوم → New Cairo`,
///   which reads as the return leg of the trip that was actually saved.
///
/// Two fixes together make it direction-proof. Each endpoint is wrapped in a
/// first-strong isolate, so it resolves internally and acts as one neutral
/// object regardless of script; and the arrow is chosen from the ambient
/// [direction], so it points from origin to destination in both an Arabic RTL
/// and an English LTR layout. The isolate controls render as nothing.
///
/// Only for text the user reads. Never write the result to the database or
/// compare it against a stored string — the isolates are real characters, and
/// `operation_bookings.route` is parsed back apart by
/// `SupabaseSeatReleaseDatasource`.
String routeDirectionLabel(
  String origin,
  String destination, {
  required TextDirection direction,
}) {
  final from = origin.trim();
  final to = destination.trim();
  if (from.isEmpty && to.isEmpty) return '';
  if (from.isEmpty) return isolatedPlaceName(to);
  if (to.isEmpty) return isolatedPlaceName(from);

  final arrow = directionArrow(direction);
  return '${isolatedPlaceName(from)} $arrow ${isolatedPlaceName(to)}';
}

/// The arrow that runs *from* the origin *to* the destination once [direction]
/// has laid the line out: leftwards in RTL, rightwards in LTR.
String directionArrow(TextDirection direction) =>
    direction == TextDirection.rtl ? _leftArrow : _rightArrow;

/// Wraps one place name in a first-strong isolate, so its own script decides
/// how it reads internally while the text around it sees a single neutral
/// object. The two controls render as nothing.
///
/// Needed per *name*, not per string: a route chain drawn as several
/// `TextSpan`s is still one bidi paragraph — spans are styling, not isolates —
/// so `New Cairo ← Adly Mansour ← Zefta` lays itself out backwards in an RTL
/// app without them.
String isolatedPlaceName(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '' : '$_isolate$trimmed$_popIsolate';
}

/// [routeDirectionLabel] rendered against the ambient [Directionality] — the
/// form to reach for whenever a screen states which way a route or a booking
/// runs.
class RouteDirectionText extends StatelessWidget {
  const RouteDirectionText({
    super.key,
    required this.origin,
    required this.destination,
    this.style,
    this.connectorStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String origin;
  final String destination;
  final TextStyle? style;

  /// Draws the arrow apart from the two place names, so a card can print the
  /// endpoints as strong names with a quiet connector between them instead of
  /// one flat run of type. Null keeps the arrow in [style].
  ///
  /// Only styling changes: the composed characters, their order, and the
  /// isolates around each name are identical either way, so the line lays
  /// itself out exactly as the plain form does. Spans are not isolates —
  /// splitting the label into three of them does not make it direction-proof,
  /// [isolatedPlaceName] does.
  final TextStyle? connectorStyle;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final label = routeDirectionLabel(
      origin,
      destination,
      direction: direction,
    );
    final connector = connectorStyle;
    final from = isolatedPlaceName(origin);
    final to = isolatedPlaceName(destination);

    // One endpoint means no arrow to style, so there is nothing for the rich
    // form to do that the plain one does not already do.
    if (connector == null || from.isEmpty || to.isEmpty) {
      return Text(
        label,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: from),
          TextSpan(text: ' ${directionArrow(direction)} ', style: connector),
          TextSpan(text: to),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

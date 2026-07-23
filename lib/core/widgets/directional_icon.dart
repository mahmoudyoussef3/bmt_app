import 'package:flutter/widgets.dart';

/// An [Icon] that horizontally mirrors itself in RTL layouts.
///
/// Only pass glyphs that genuinely imply a direction of travel (back/forward
/// arrows, chevrons, send). Universal glyphs (search, close, settings…) must
/// keep using a plain [Icon].
///
/// Most Material directional glyphs — every `arrow_back*`, `arrow_forward*` and
/// `chevron_*` variant — already declare [IconData.matchTextDirection], and
/// [Icon] mirrors those itself under RTL. Flipping them again here would cancel
/// that out and leave the arrow pointing the wrong way in Arabic, so this
/// widget mirrors *only* the glyphs Flutter will not mirror on its own (for
/// example [Icons.send], which is directional but not flagged).
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: size, color: color);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (!isRtl || icon.matchTextDirection) return glyph;
    return Transform.flip(flipX: true, child: glyph);
  }
}

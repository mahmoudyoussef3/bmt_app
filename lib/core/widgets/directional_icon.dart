import 'package:flutter/widgets.dart';

/// An [Icon] that horizontally mirrors itself in RTL layouts.
///
/// Material's arrow and chevron glyphs are not flagged as directional, so
/// `Icon(Icons.arrow_back)` keeps pointing left even in an Arabic layout where
/// "back" means "to the right". Wrap those glyphs in this widget so the arrow
/// follows the reading direction. Universal glyphs (search, close, settings…)
/// must keep using a plain [Icon] — only pass icons that genuinely imply a
/// direction of travel (back/forward arrows, chevrons, send).
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final glyph = Icon(icon, size: size, color: color);
    if (!isRtl) return glyph;
    return Transform.flip(flipX: true, child: glyph);
  }
}

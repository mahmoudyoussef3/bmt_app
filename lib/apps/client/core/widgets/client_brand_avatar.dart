import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_palette.dart';

/// The design's operator mark: a brand tile carrying a single glyph.
///
/// This is `avatarStyle(size)` from the design file — every dimension is
/// derived from [size] exactly as it is there (radius `0.32×`, glyph `0.4×`,
/// a `--primary-tint` lift underneath) — so a 24px mark inside a route card
/// and a 44px mark atop an office profile are visibly the same object at two
/// scales.
///
/// [brandKey] used to pick one of three per-office colour ramps. Every mark now
/// carries the house brand instead: an office is told apart by its logo and its
/// name, and the colour of a tile is not something a rider should have to
/// learn. The parameter is kept so call sites that already pass an office id
/// keep working, and so a real per-office brand colour has a seam to land in.
///
/// The design fills this tile with the operator's first letter. This app does
/// not, and that is deliberate: a single Arabic letter torn off a trading name
/// ("شركة الدلتا للنقل" → "ش") identifies nothing, where a Latin acronym would.
/// Use [ClientBrandAvatar.glyph] with a storefront icon for operators, and keep
/// [ClientBrandAvatar.initial] for the places a short, self-contained name
/// really is the mark.
class ClientBrandAvatar extends StatelessWidget {
  const ClientBrandAvatar.glyph({
    super.key,
    required IconData icon,
    this.size = 44,
    this.brandKey,
    this.circle = false,
  }) : _icon = icon,
       _initial = null;

  const ClientBrandAvatar.initial({
    super.key,
    required String text,
    this.size = 44,
    this.brandKey,
    this.circle = false,
  }) : _icon = null,
       _initial = text;

  final double size;
  final String? brandKey;

  /// Draws a circle instead of the design's rounded square. For the few spots
  /// that already frame operators as circles.
  final bool circle;

  final IconData? _icon;
  final String? _initial;

  /// The first character of [name] — never two, which in Arabic pulls an
  /// unrelated letter out of the middle of a word.
  static String initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final foreground = ClientColors.onPrimaryFor(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClientPalette.of(context).primary,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primaryTintFor(context),
            blurRadius: size * 0.36,
            offset: Offset(0, size * 0.18),
          ),
        ],
      ),
      child: _icon != null
          ? Icon(_icon, size: size * 0.5, color: foreground)
          : Text(
              _initial!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
                height: 1,
              ),
            ),
    );
  }
}

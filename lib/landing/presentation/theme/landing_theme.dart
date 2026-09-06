import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The landing page's own design tokens, ported one-for-one from the
/// `EWT Landing v2` design file's `styleVars` block.
///
/// The marketing page deliberately does **not** read [DashboardColors] or the
/// product themes: the redesign moves the site onto a warm paper ground
/// (`#F8F7F4`) with depth coming from borders rather than shadow, while the
/// product apps keep their own palettes. Keeping the two separate means this
/// page can match the design exactly without dragging the console with it.
class LandingPalette {
  const LandingPalette._();

  // Brand
  static const brand = Color(0xFF004F7E);
  static const brandInk = Color(0xFF004F7E);
  static const brandTint = Color(0xFFEAF0FD);
  static const brandLine = Color(0xFFC9D9FB);
  static const brandDeep = Color(0xFF3730A3);

  /// The dark band colour behind the hero preview, the dashboard section, the
  /// steps section, the closing CTA panel and the footer.
  static const navy = Color(0xFF0B1B34);

  /// The pale blue used for eyebrows and icons *on* the navy bands, where
  /// [brand] itself has too little contrast.
  static const onNavyAccent = Color(0xFF7CB0FB);

  // Surface ladder
  static const page = Color(0xFFF8F7F4);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFBFAF7);
  static const raised = Color(0xFFF2EFE9);
  static const well = Color(0xFFEDE9E0);

  // Borders
  static const border = Color(0xFFE7E1D6);
  static const borderSoft = Color(0xFFF0ECE3);
  static const borderStrong = Color(0xFFD5CDBE);

  // Ink
  static const ink = Color(0xFF1C1917);
  static const muted = Color(0xFF6B6258);
  static const faint = Color(0xFF9C948A);

  // Status tones — each is a (solid, tint, line) triple.
  static const ok = Color(0xFF0E7490);
  static const good = Color(0xFF15803D);
  static const goodTint = Color(0xFFE7F4EA);
  static const goodLine = Color(0xFFBFE3C7);
  static const warn = Color(0xFFB45309);
  static const warnTint = Color(0xFFFBF0DB);
  static const warnLine = Color(0xFFEBD5AE);
  static const bad = Color(0xFFC62828);
  static const badTint = Color(0xFFFBEAE7);
  static const badLine = Color(0xFFF0CFC9);

  /// The green used for "live" dots on the navy bands.
  static const live = Color(0xFF34D399);

  /// `--shadow: 0 1px 2px rgba(28,25,23,.05)` — a contact line, not an
  /// ambient glow. Cards in this design sit on the page, they do not float.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// The one exception to [cardShadow]: the hero's dashboard preview and the
  /// dark-band panels, which the design does lift off the page.
  static const List<BoxShadow> liftedShadow = [
    BoxShadow(
      color: Color(0x2E0B1B34),
      offset: Offset(0, 28),
      blurRadius: 64,
      spreadRadius: -30,
    ),
    BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 4), blurRadius: 14),
  ];
}

/// `--r-card` / `--r-btn` / `--r-badge` from the design's soft-corner preset.
class LandingRadii {
  const LandingRadii._();

  static const double card = 14;
  static const double button = 10;
  static const double badge = 6;

  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonR = BorderRadius.all(Radius.circular(button));
  static const BorderRadius badgeR = BorderRadius.all(Radius.circular(badge));
}

/// The five badge tones from the design's `B` map. Each resolves to a
/// tint background, a solid foreground and a matching line.
enum LandingTone { brand, good, warn, bad, neutral }

extension LandingToneStyle on LandingTone {
  Color get background => switch (this) {
    LandingTone.brand => LandingPalette.brandTint,
    LandingTone.good => LandingPalette.goodTint,
    LandingTone.warn => LandingPalette.warnTint,
    LandingTone.bad => LandingPalette.badTint,
    LandingTone.neutral => LandingPalette.raised,
  };

  Color get foreground => switch (this) {
    LandingTone.brand => LandingPalette.brandInk,
    LandingTone.good => LandingPalette.good,
    LandingTone.warn => LandingPalette.warn,
    LandingTone.bad => LandingPalette.bad,
    LandingTone.neutral => LandingPalette.muted,
  };

  Color get line => switch (this) {
    LandingTone.brand => LandingPalette.brandLine,
    LandingTone.good => LandingPalette.goodLine,
    LandingTone.warn => LandingPalette.warnLine,
    LandingTone.bad => LandingPalette.badLine,
    LandingTone.neutral => LandingPalette.border,
  };
}

/// Cairo at the design's exact sizes and weights.
///
/// The design leans on weights the product themes never use — 800 and 900 do
/// most of the typographic work, with 600/700 for supporting copy — so the
/// landing page states its ramp here rather than bending the shared
/// [AppTextThemes] scale into a shape only this page wants.
///
/// **A style only sets `height` where the design sets `line-height`.** Cairo's
/// own line box is 1.874x its size (typo ascent 1303, descent -571, with
/// `USE_TYPO_METRICS` set), and that is what the browser gives every heading,
/// figure, label and badge in the design — none of which declare a
/// `line-height`. Pinning those to a tight ratio here quietly took a third of
/// the vertical rhythm out of the whole page, and the phone mockups, which are
/// nothing but stacked labels and figures, lost the most.
class LandingType {
  const LandingType._();

  static TextStyle _cairo(
    double size,
    FontWeight weight, {
    Color color = LandingPalette.ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.cairo(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Hero headline. Size is supplied by the caller because the design clamps
  /// it against the viewport (`clamp(30px, 4.6vw, 56px)`).
  static TextStyle display(double size, {Color color = LandingPalette.ink}) =>
      _cairo(
        size,
        FontWeight.w900,
        color: color,
        height: 1.22,
        letterSpacing: -1.2,
      );

  /// Section headline — `clamp(25px, 3.2vw, 40px)`.
  static TextStyle heading(double size, {Color color = LandingPalette.ink}) =>
      _cairo(
        size,
        FontWeight.w900,
        color: color,
        height: 1.3,
        letterSpacing: -0.8,
      );

  /// The small coloured label above a section headline.
  static TextStyle eyebrow({Color color = LandingPalette.brandInk}) =>
      _cairo(12, FontWeight.w800, color: color, letterSpacing: 0.5);

  /// Section lead paragraph.
  static TextStyle lead(double size, {Color color = LandingPalette.muted}) =>
      _cairo(size, FontWeight.w400, color: color, height: 1.9);

  /// A card's heading. The design gives these no `line-height`, so neither
  /// does this — see the note on [LandingType].
  static TextStyle cardTitle(double size, {Color color = LandingPalette.ink}) =>
      _cairo(size, FontWeight.w900, color: color);

  static TextStyle cardBody(
    double size, {
    Color color = LandingPalette.muted,
  }) => _cairo(size, FontWeight.w400, color: color, height: 1.8);

  /// A metric's number — tight tracking, heaviest weight, and Cairo's own
  /// line box, which is what the design's figures sit in.
  static TextStyle metric(double size, {Color color = LandingPalette.ink}) =>
      _cairo(size, FontWeight.w900, color: color, letterSpacing: -0.8);

  static TextStyle label(
    double size, {
    Color color = LandingPalette.muted,
    FontWeight weight = FontWeight.w700,
  }) => _cairo(size, weight, color: color);

  static TextStyle badge({Color color = LandingPalette.ink}) =>
      _cairo(10.5, FontWeight.w800, color: color);
}

import 'package:flutter/material.dart';

/// The EWT Rider design-system palette, resolved per brightness.
///
/// Every value here is the sRGB conversion of the OKLCH token declared by the
/// `EWT Rider App` Claude Design project, so the app and the design file stay
/// literally the same colour rather than "about the same". The design defines
/// its palette as CSS custom properties on `:root` / `[data-theme="dark"]`;
/// this class is the Dart mirror of those two blocks.
///
/// Nothing in the app should reference these fields directly — [ClientColors]
/// is the named surface every widget reads, and it resolves through here. Keep
/// that direction: a token gains a *name* in `ClientColors`, a *value* here.
@immutable
class ClientPalette {
  const ClientPalette._({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textDisabled,
    required this.primary,
    required this.primaryStrong,
    required this.onPrimary,
    required this.primary2,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.neutral,
    required this.neutralBg,
    required this.rating,
    required this.shadow,
    required this.shadowAlphaScale,
    required this.heroTop,
    required this.heroBottom,
    required this.heroText,
  });

  /// `--bg` — the page ground behind every scroll view.
  final Color bg;

  /// `--surface` — cards, sheets, app bars, the tab bar.
  final Color surface;

  /// `--surface-2` — inputs, chips, seat tiles, skeleton bars, inert fills.
  final Color surface2;

  /// `--border` — the hairline on every card, field and divider.
  final Color border;

  /// A darker hairline for focused fields and emphasised separators.
  ///
  /// Not a design token: the design draws every edge with `--border`, but
  /// Material needs a second step for focus/hover so the two states differ.
  final Color borderStrong;

  /// `--text` / `--text-muted` — the two-step text ramp the design uses.
  final Color text;
  final Color textMuted;

  /// Disabled text — between [textMuted] and [border] on the same ramp.
  final Color textDisabled;

  /// `--primary` — the deep EWT blue that carries every action.
  final Color primary;

  /// `--primary-strong` — pressed primary, and the ink on primary containers.
  final Color primaryStrong;

  /// `--on-primary` — text and icons on a filled primary surface.
  final Color onPrimary;

  /// `--primary-2` — the teal the brand gradients run to. Never a solo accent.
  final Color primary2;

  /// The soft brand container (`--primary` at low chroma) and its ink.
  final Color primaryContainer;
  final Color onPrimaryContainer;

  /// `--success` / `--success-bg` … the design's three status pairs, plus a
  /// neutral pair for completed/inert states which the design renders with
  /// `--text-muted` on `--surface-2`.
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color neutral;
  final Color neutralBg;

  /// Stars only. The design keeps ratings off the warning ramp on purpose so a
  /// 4.8-star office never reads as a caution.
  final Color rating;

  /// `--shadow`, plus the multiplier that keeps dark-mode lift visible.
  ///
  /// A shadow works by darkening what sits behind it, so the light-mode alpha
  /// over a near-white page is a crisp edge while the same alpha over the dark
  /// page is nothing at all. The design solves this by declaring a much
  /// stronger `--shadow` in the dark block; [shadowAlphaScale] is that same
  /// jump expressed as a factor so [ClientElevation] keeps one alpha table.
  final Color shadow;
  final double shadowAlphaScale;

  /// `--home-hero-1` / `--home-hero-2` / `--home-hero-text` — the home header.
  final Color heroTop;
  final Color heroBottom;
  final Color heroText;

  /// `--primary-tint` — primary at 12% (light) / 18% (dark).
  Color get primaryTint => primary.withValues(alpha: _isDark ? 0.18 : 0.12);

  /// `--primary-2-tint` — primary-2 at 10% (light) / 14% (dark).
  Color get primary2Tint => primary2.withValues(alpha: _isDark ? 0.14 : 0.10);

  bool get _isDark => bg.computeLuminance() < 0.5;

  /// The brand fill on office avatars, step markers and the active-trip card.
  ///
  /// The design draws this as `linear-gradient(135deg,--primary,--primary-2)`,
  /// but the app deliberately paints it **flat [primary]**: a blue-to-teal ramp
  /// puts two hues behind one piece of content, so a ticket header read as two
  /// different brands depending on which end you looked at. One colour is also
  /// the only way a filled surface keeps a single, checkable contrast ratio
  /// against [onPrimary].
  ///
  /// It stays a [Gradient] so the widgets that paint a brand surface keep one
  /// shape; both stops are the same colour, which renders as a solid fill.
  LinearGradient get brandGradient =>
      LinearGradient(colors: [primary, primary]);

  /// The tall header behind Home, Trips, Routes, Offices and Profile.
  ///
  /// Flat for the same reason as [brandGradient] — [heroTop] and [heroBottom]
  /// are one colour per brightness, so the two ends are kept in step by the
  /// palette rather than by a stop list.
  LinearGradient get heroGradient =>
      LinearGradient(colors: [heroTop, heroBottom]);

  static const ClientPalette light = ClientPalette._(
    bg: Color(0xFFFAF8F5),
    surface: Color(0xFFFEFDFC),
    surface2: Color(0xFFF0EEEB),
    border: Color(0xFFE0DDDA),
    borderStrong: Color(0xFFCECAC5),
    text: Color(0xFF201C18),
    textMuted: Color(0xFF67635D),
    textDisabled: Color(0xFF95928D),
    primary: Color(0xFF004F7E),
    primaryStrong: Color(0xFF003866),
    onPrimary: Color(0xFFFCFCFC),
    primary2: Color(0xFF00848B),
    primaryContainer: Color(0xFFD2ECFC),
    onPrimaryContainer: Color(0xFF003866),
    success: Color(0xFF137738),
    successBg: Color(0xFFD5F5DA),
    warning: Color(0xFFA75D00),
    warningBg: Color(0xFFFFE5C0),
    danger: Color(0xFFB32228),
    dangerBg: Color(0xFFFFDFDA),
    neutral: Color(0xFF67635D),
    neutralBg: Color(0xFFF0EEEB),
    rating: Color(0xFFE2A520),
    shadow: Color(0xFF14141E),
    shadowAlphaScale: 1.0,
    heroTop: Color(0xFF004F7E),
    heroBottom: Color(0xFF004F7E),
    heroText: Color(0xFFF3F5F8),
  );

  static const ClientPalette dark = ClientPalette._(
    bg: Color(0xFF0E0F12),
    surface: Color(0xFF181B1E),
    surface2: Color(0xFF24272B),
    border: Color(0xFF303338),
    borderStrong: Color(0xFF44484E),
    text: Color(0xFFE6E8EA),
    textMuted: Color(0xFF8C8F95),
    textDisabled: Color(0xFF66696F),
    primary: Color(0xFF39B4DD),
    primaryStrong: Color(0xFF51C7F1),
    onPrimary: Color(0xFF030D11),
    primary2: Color(0xFF53C1C7),
    primaryContainer: Color(0xFF0A3341),
    onPrimaryContainer: Color(0xFF93D9F5),
    success: Color(0xFF56AE6C),
    successBg: Color(0xFF15301B),
    warning: Color(0xFFE29E47),
    warningBg: Color(0xFF412805),
    danger: Color(0xFFEA6A64),
    dangerBg: Color(0xFF47211E),
    neutral: Color(0xFF8C8F95),
    neutralBg: Color(0xFF24272B),
    rating: Color(0xFFF3B94C),
    shadow: Color(0xFF000000),
    shadowAlphaScale: 5.0,
    heroTop: Color(0xFF00244D),
    heroBottom: Color(0xFF00244D),
    heroText: Color(0xFFF3F5F8),
  );

  static ClientPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static ClientPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

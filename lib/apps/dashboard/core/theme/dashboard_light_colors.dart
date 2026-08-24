import 'package:flutter/material.dart';

/// EWT dashboard light palette — warm paper neutrals.
///
/// Scoped to the dashboard app only. The client and captain apps are drawn in
/// [AppLightColors](../../../core/theme/app_light_colors.dart) — a cool slate
/// palette with its own, separately designed visual identity — and this file
/// deliberately does not touch it. The console gets its own console palette,
/// the same way it already has its own [DashboardAppTheme] and its own Cairo
/// typography.
///
/// Same roles as [AppLightColors], same intent, new values: a warm off-white
/// page (#F7F5F1) instead of cool slate, warm near-black ink instead of navy,
/// and depth carried by borders rather than a two-layer ambient shadow — see
/// [softShadow].
abstract final class DashboardLightColors {
  /// Cut into the surface — chart plot areas, progress tracks, inset wells.
  static const Color canvas = Color(0xFFEDE9E0);

  /// The page.
  static const Color background = Color(0xFFF7F5F1);

  /// The sidebar and other quiet bands: a half step from the page toward a card.
  static const Color surfaceLow = Color(0xFFFBF9F5);

  /// Cards, sheets, dialogs, table bodies.
  static const Color surface = Color(0xFFFFFFFF);

  /// A tile nested inside a card, and the table header band.
  static const Color surfaceRaised = Color(0xFFF2EFE8);

  /// Input fills, skeleton bases, quiet buttons.
  static const Color surfaceHighest = Color(0xFFEDE9E0);

  static const Color onSurface = Color(0xFF1C1917);
  static const Color onSurfaceMuted = Color(0xFF6B6258);

  /// Placeholders and disabled text. Darkened one step off the original
  /// #9C948A (2026-08-24): that value sat under 3.2:1 on white, so an unfilled
  /// hint read as barely-there rather than quietly secondary.
  static const Color onSurfaceFaint = Color(0xFF877C6F);
  static const Color onFilled = Color(0xFFFFFFFF);

  /// Card borders. Warm enough to sit on the paper page without reading grey.
  static const Color border = Color(0xFFE7E1D6);

  /// A line inside an already-bordered surface (row rules, panel separators).
  static const Color borderSubtle = Color(0xFFF0ECE3);

  /// A border doing the separating on its own: input edges, selected tiles.
  static const Color borderStrong = Color(0xFFD5CDBE);

  /// The selected nav row's fill. Warm, not brand-tinted: the brand is spent on
  /// the 2px inline edge instead, so the sidebar never reads as a wall of blue.
  static const Color navSelected = Color(0xFFF1EEE7);

  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFE1EBFC);
  static const Color onPrimaryContainer = Color(0xFF16389B);
  static const Color primaryLine = Color(0xFFBBD0FA);
  static const Color primaryDeep = Color(0xFF4338CA);

  /// The focused-input border and floating label. Split off from
  /// [primaryAccent] (which stays doing link/ink duty) so a focused field can
  /// be tuned for visibility alone rather than sharing a value with quieter
  /// accent uses.
  static const Color focus = Color(0xFF2F6FED);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const Color success = Color(0xFF0E7490);
  static const Color successInk = Color(0xFF0E7490);
  static const Color successContainer = Color(0xFFD9F0F3);
  static const Color onSuccessContainer = Color(0xFF0B5A70);
  static const Color successLine = Color(0xFFA9D9E0);

  /// Warmed one step off #B45309 (2026-08-24) for a livelier alert read.
  static const Color warning = Color(0xFFB8560A);
  static const Color warningInk = Color(0xFFB8560A);
  static const Color warningContainer = Color(0xFFFCE7BE);
  static const Color onWarningContainer = Color(0xFF7C3D07);
  static const Color warningLine = Color(0xFFE7C98C);

  static const Color danger = Color(0xFFC62828);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color dangerInk = Color(0xFFC62828);
  static const Color dangerContainer = Color(0xFFFADEDA);
  static const Color onDangerContainer = Color(0xFF8C1D18);
  static const Color dangerLine = Color(0xFFEBBFB7);

  static const Color info = primaryAccent;
  static const Color infoContainer = primaryContainer;
  static const Color onInfoContainer = onPrimaryContainer;

  static const Color neutral = onSurfaceMuted;
  static const Color neutralContainer = surfaceRaised;
  static const Color onNeutralContainer = onSurfaceMuted;

  static const Color special = Color(0xFF6D28D9);
  static const Color specialContainer = Color(0xFFEAE1FC);
  static const Color onSpecialContainer = Color(0xFF4C1D95);
  static const Color specialLine = Color(0xFFD2C2F8);

  static const Color rating = Color(0xFFB8560A);

  /// Warm shadow tint — a neutral black shadow over paper reads grey and dirty.
  static const Color shadow = Color(0xFF1C1917);
  static const Color scrim = Color(0x731C1917);

  /// A card on the page. Deliberately almost nothing: on this palette a card is
  /// separated by its border and its lighter fill, not by lift.
  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x0D1C1917), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Reserved for things that genuinely float: dialogs, menus, popovers.
  static List<BoxShadow> get floatingShadow => const [
    BoxShadow(
      color: Color(0x381C1917),
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
    BoxShadow(color: Color(0x0F1C1917), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

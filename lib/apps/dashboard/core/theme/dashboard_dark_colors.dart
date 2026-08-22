import 'package:flutter/material.dart';

/// EWT dashboard dark palette — the same console design under different light.
///
/// Scoped to the dashboard app only; see [DashboardLightColors] for why this
/// does not touch the shared [AppDarkColors](../../../core/theme/app_dark_colors.dart)
/// that the client and captain apps are drawn in.
abstract final class DashboardDarkColors {
  static const Color canvas = Color(0xFF0B111A);
  static const Color background = Color(0xFF0E141E);
  static const Color surfaceLow = Color(0xFF121A26);
  static const Color surface = Color(0xFF161E2B);
  static const Color surfaceRaised = Color(0xFF1D2637);
  static const Color surfaceHighest = Color(0xFF283243);

  static const Color onSurface = Color(0xFFF1F5F9);
  static const Color onSurfaceMuted = Color(0xFF94A3B8);
  static const Color onSurfaceFaint = Color(0xFF64748B);
  static const Color onFilled = Color(0xFFFFFFFF);

  static const Color border = Color(0xFF283243);
  static const Color borderSubtle = Color(0xFF1E2836);
  static const Color borderStrong = Color(0xFF3A4557);

  /// Selected nav row — a lifted surface, with the brand carried by the 2px
  /// inline edge, exactly as in light mode.
  static const Color navSelected = Color(0xFF1B2434);

  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFF7CB0FB);
  static const Color primaryContainer = Color(0xFF152541);
  static const Color onPrimaryContainer = Color(0xFFCFE0FE);
  static const Color primaryLine = Color(0xFF26436F);
  static const Color primaryDeep = Color(0xFF4338CA);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const Color success = Color(0xFF0E7490);
  static const Color successInk = Color(0xFF2CC0D8);
  static const Color successContainer = Color(0xFF10303A);
  static const Color onSuccessContainer = Color(0xFF9BE7F2);
  static const Color successLine = Color(0xFF1C4C59);

  static const Color warning = Color(0xFFB45309);
  static const Color warningInk = Color(0xFFF0B44B);
  static const Color warningContainer = Color(0xFF3A2C10);
  static const Color onWarningContainer = Color(0xFFF8DDA8);
  static const Color warningLine = Color(0xFF5A441A);

  static const Color danger = Color(0xFFC62828);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color dangerInk = Color(0xFFF58484);
  static const Color dangerContainer = Color(0xFF3A1A1A);
  static const Color onDangerContainer = Color(0xFFF8C8C8);
  static const Color dangerLine = Color(0xFF5C2A2A);

  static const Color info = primaryAccent;
  static const Color infoContainer = primaryContainer;
  static const Color onInfoContainer = onPrimaryContainer;

  static const Color neutral = onSurfaceMuted;
  static const Color neutralContainer = surfaceRaised;
  static const Color onNeutralContainer = Color(0xFFCBD5E1);

  static const Color special = Color(0xFFB39BFB);
  static const Color specialContainer = Color(0xFF241C3C);
  static const Color onSpecialContainer = Color(0xFFDDD1FA);
  static const Color specialLine = Color(0xFF3B2E63);

  static const Color rating = Color(0xFFF0B44B);

  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xCC060B15);

  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x59000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get floatingShadow => const [
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 36,
      offset: Offset(0, 14),
      spreadRadius: -10,
    ),
    BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

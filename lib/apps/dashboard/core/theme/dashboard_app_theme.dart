import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_color_scheme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Dashboard-scoped theme: the EWT console's own palette, typography and
/// component styling.
///
/// This used to be a thin overlay — Cairo font plus [AppSurfaceStyle] — on top
/// of the shared [AppTheme] that the client and captain apps also use. The EWT
/// redesign gave the console its own palette
/// ([DashboardLightColors]/[DashboardDarkColors]), so this now builds a
/// complete [ThemeData] the same way [AppTheme] does, rather than decorating
/// it: every component theme states a colour explicitly, sourced from the
/// dashboard palette, so nothing falls through to a hard-coded client/captain
/// literal (or, worse, a Material default) and the console cannot end up with
/// old-palette and new-palette chrome mixed on the same screen.
class DashboardAppTheme {
  DashboardAppTheme._();

  static ThemeData light() => _build(
    brightness: Brightness.light,
    colorScheme: dashboardLightColorScheme(),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colorScheme: dashboardDarkColorScheme(),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    final dark = brightness == Brightness.dark;
    final background = dark
        ? DashboardDarkColors.background
        : DashboardLightColors.background;
    final surface = dark
        ? DashboardDarkColors.surface
        : DashboardLightColors.surface;
    final surfaceRaised = dark
        ? DashboardDarkColors.surfaceRaised
        : DashboardLightColors.surfaceRaised;
    final surfaceHighest = dark
        ? DashboardDarkColors.surfaceHighest
        : DashboardLightColors.surfaceHighest;
    final onSurface = dark
        ? DashboardDarkColors.onSurface
        : DashboardLightColors.onSurface;
    final onSurfaceMuted = dark
        ? DashboardDarkColors.onSurfaceMuted
        : DashboardLightColors.onSurfaceMuted;
    final onSurfaceFaint = dark
        ? DashboardDarkColors.onSurfaceFaint
        : DashboardLightColors.onSurfaceFaint;
    final border = dark
        ? DashboardDarkColors.border
        : DashboardLightColors.border;
    final borderStrong = dark
        ? DashboardDarkColors.borderStrong
        : DashboardLightColors.borderStrong;
    final primary = dark
        ? DashboardDarkColors.primary
        : DashboardLightColors.primary;
    final onPrimary = dark
        ? DashboardDarkColors.onPrimary
        : DashboardLightColors.onPrimary;
    final primaryAccent = dark
        ? DashboardDarkColors.primaryAccent
        : DashboardLightColors.primaryAccent;
    final primaryContainer = dark
        ? DashboardDarkColors.primaryContainer
        : DashboardLightColors.primaryContainer;
    // Light mode gets a focus ring split off from primaryAccent so a focused
    // field reads as active on its own, without recoloring links/accent ink;
    // dark mode is untouched and keeps sharing primaryAccent for both roles.
    final focus = dark ? primaryAccent : DashboardLightColors.focus;
    final dangerInk = dark
        ? DashboardDarkColors.dangerInk
        : DashboardLightColors.dangerInk;
    final danger = dark
        ? DashboardDarkColors.danger
        : DashboardLightColors.danger;
    final shadow = dark
        ? DashboardDarkColors.shadow
        : DashboardLightColors.shadow;
    final scrim = dark ? DashboardDarkColors.scrim : DashboardLightColors.scrim;

    final textTheme = _dashboardTextTheme(colorScheme);
    final hairline = BorderSide(color: border);

    OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: side,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: border,
      shadowColor: shadow,
      splashColor: primaryAccent.withAlpha(20),
      highlightColor: primaryAccent.withAlpha(14),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hairline,
        ),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: onSurface),
      primaryIconTheme: IconThemeData(color: onSurface),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceHighest,
          disabledForegroundColor: onSurfaceFaint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceHighest,
          disabledForegroundColor: onSurfaceFaint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          disabledForegroundColor: onSurfaceFaint,
          side: hairline,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryAccent,
          disabledForegroundColor: onSurfaceFaint,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
          disabledForegroundColor: onSurfaceFaint,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: Colors.white24,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? surfaceHighest : surface,
        border: inputBorder(hairline),
        enabledBorder: inputBorder(hairline),
        disabledBorder: inputBorder(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: inputBorder(BorderSide(color: focus, width: 2)),
        errorBorder: inputBorder(BorderSide(color: dangerInk)),
        focusedErrorBorder: inputBorder(BorderSide(color: dangerInk, width: 2)),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: focus),
        helperStyle: textTheme.bodySmall?.copyWith(color: onSurfaceMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: dangerInk),
        prefixIconColor: onSurfaceMuted,
        suffixIconColor: onSurfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: focus,
        selectionColor: focus.withAlpha(dark ? 60 : 50),
        selectionHandleColor: focus,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scrim,
        dragHandleColor: border,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: scrim,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: scrim,
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? surfaceRaised : surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: hairline,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            dark ? surfaceRaised : surface,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              side: hairline,
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? surfaceHighest : onSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: dark ? Border.fromBorderSide(hairline) : null,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: dark ? onSurface : surface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? surfaceRaised : onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: dark ? onSurface : surface,
        ),
        actionTextColor: primaryAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: dark ? hairline : BorderSide.none,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? primaryAccent.withAlpha(38) : primaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryAccent
                : onSurfaceMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? primaryAccent
                : onSurfaceMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryAccent,
        unselectedItemColor: onSurfaceMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: dark ? primaryAccent.withAlpha(38) : primaryContainer,
        selectedIconTheme: IconThemeData(color: primaryAccent),
        unselectedIconTheme: IconThemeData(color: onSurfaceMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: primaryAccent,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: onSurfaceMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryAccent,
        unselectedLabelColor: onSurfaceMuted,
        indicatorColor: primaryAccent,
        dividerColor: border,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceHighest,
        selectedColor: primaryContainer,
        disabledColor: surfaceHighest.withAlpha(120),
        checkmarkColor: dark
            ? DashboardDarkColors.onPrimaryContainer
            : DashboardLightColors.onPrimaryContainer,
        side: hairline,
        labelStyle: textTheme.labelLarge?.copyWith(color: onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: dark
              ? DashboardDarkColors.onPrimaryContainer
              : DashboardLightColors.onPrimaryContainer,
        ),
        iconTheme: IconThemeData(color: onSurfaceMuted, size: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: danger,
        textColor: dark
            ? DashboardDarkColors.onDanger
            : DashboardLightColors.onDanger,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceMuted,
        textColor: onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: onSurfaceMuted),
        selectedColor: primaryAccent,
        selectedTileColor: primaryAccent.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? onPrimary
              : (dark ? onSurfaceMuted : surface),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : surfaceHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : borderStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(onPrimary),
        side: BorderSide(color: borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? primaryAccent : primary)
              : onSurfaceMuted,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceHighest,
        thumbColor: dark ? primaryAccent : primary,
        overlayColor: (dark ? primaryAccent : primary).withAlpha(38),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? primaryAccent : primary,
        linearTrackColor: surfaceHighest,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: surface,
      ),

      extensions: [AppSurfaceStyle.ewt(colorScheme)],
    );
  }

  static TextTheme _dashboardTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.cairoTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      decorationColor: scheme.onSurface,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: 0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.22,
        letterSpacing: 0,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.55,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
      ),
    );
  }
}

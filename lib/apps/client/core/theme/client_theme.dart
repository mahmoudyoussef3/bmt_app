import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client_colors.dart';
import 'client_design_tokens.dart';

abstract final class ClientTheme {
  const ClientTheme._();

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ClientColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: ClientColors.primary,
          onPrimary: ClientColors.textInverse,
          secondary: ClientColors.secondary,
          tertiary: ClientColors.accent,
          surface: ClientColors.surface,
          surfaceContainerLowest: ClientColors.surface,
          surfaceContainerLow: ClientColors.surfaceSubtle,
          surfaceContainer: ClientColors.surfaceMuted,
          surfaceContainerHigh: ClientColors.surfaceRaised,
          surfaceContainerHighest: ClientColors.surfaceMuted,
          onSurface: ClientColors.textPrimary,
          onSurfaceVariant: ClientColors.textSecondary,
          outline: ClientColors.border,
          outlineVariant: ClientColors.borderStrong,
          error: ClientColors.journeyRed,
        );
    return _build(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ClientColors.darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: ClientColors.darkPrimary,
          onPrimary: const Color(0xFF061226),
          secondary: ClientColors.darkSecondary,
          tertiary: ClientColors.darkAccent,
          surface: const Color(0xFF101A2E),
          surfaceContainerLowest: const Color(0xFF0B1220),
          surfaceContainerLow: const Color(0xFF0D1728),
          surfaceContainer: const Color(0xFF17233A),
          surfaceContainerHigh: const Color(0xFF15213A),
          surfaceContainerHighest: const Color(0xFF15213A),
          onSurface: const Color(0xFFF6F9FF),
          onSurfaceVariant: const Color(0xFFC3D0E2),
          outline: const Color(0xFF293B59),
          outlineVariant: const Color(0xFF3A5174),
          error: const Color(0xFFFB7185),
        );
    return _build(scheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      _textTheme(scheme),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0B1220)
          : ClientColors.surfaceSubtle,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF0B1220)
            : ClientColors.surfaceSubtle,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          side: BorderSide(color: scheme.outline.withAlpha(isDark ? 50 : 80)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withAlpha(isDark ? 50 : 80),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
        circularTrackColor: scheme.surfaceContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withAlpha(95),
          disabledForegroundColor: scheme.onPrimary.withAlpha(170),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withAlpha(190), width: 1.3),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 44),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withAlpha(160),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ClientSpacing.md,
          vertical: ClientSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          borderSide: BorderSide(color: scheme.outline.withAlpha(150)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.7),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary.withAlpha(isDark ? 55 : 28),
        disabledColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outline.withAlpha(120)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ClientRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.lg),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF17233A)
            : const Color(0xFF111827),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          side: BorderSide(color: scheme.outline.withAlpha(120)),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface.withAlpha(isDark ? 245 : 250),
        indicatorColor: scheme.primary.withAlpha(isDark ? 48 : 28),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 22,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        height: 1.06,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        height: 1.16,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.28,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.46,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.42,
        letterSpacing: 0,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

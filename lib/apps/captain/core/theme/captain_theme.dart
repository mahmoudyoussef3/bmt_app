import 'package:flutter/material.dart';
import 'captain_colors.dart';
import 'captain_typography.dart';
import 'captain_spacing.dart';

class CaptainTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: CaptainColors.primary,
        onPrimary: CaptainColors.onPrimary,
        surface: CaptainColors.surfaceLight,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: Color(0xFFF1F5F9),
        surfaceContainerLowest: CaptainColors.backgroundLight,
        outline: CaptainColors.dividerLight,
        error: CaptainColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: CaptainColors.backgroundLight,
      textTheme: CaptainTypography.textTheme(false),
      dividerTheme: const DividerThemeData(
        color: CaptainColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CaptainColors.surfaceLight,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: CaptainTypography.textTheme(false).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: CaptainColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CaptainRadius.rXl,
          side: const BorderSide(color: CaptainColors.dividerLight),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CaptainColors.surfaceLight,
        selectedItemColor: CaptainColors.primary,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CaptainColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        surface: CaptainColors.surfaceDark,
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF334155),
        surfaceContainerLowest: CaptainColors.backgroundDark,
        outline: CaptainColors.dividerDark,
        error: CaptainColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: CaptainColors.backgroundDark,
      textTheme: CaptainTypography.textTheme(true),
      dividerTheme: const DividerThemeData(
        color: CaptainColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CaptainColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: CaptainTypography.textTheme(true).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: CaptainColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CaptainRadius.rXl,
          side: const BorderSide(color: CaptainColors.dividerDark),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CaptainColors.surfaceDark,
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CaptainColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

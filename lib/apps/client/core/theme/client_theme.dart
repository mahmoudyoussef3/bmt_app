import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/core/theme/text_themes.dart';

import 'client_design_tokens.dart';
import 'client_palette.dart';

/// The shared [AppTheme], repainted in the EWT Rider palette and rendered in
/// Cairo.
///
/// Two things are happening here, and they are separate on purpose:
///
/// * **Typeface.** The shared scale is set in Outfit, a Latin-only face, so
///   every Arabic string in this Arabic-first app was falling back to whatever
///   the device happened to have. Cairo covers both scripts and is already what
///   the captain and dashboard apps use. It has to go in through
///   `textThemeBuilder` — every component style in [AppTheme] is derived from
///   `textTheme`, so a later `copyWith(textTheme: …)` would repaint the body
///   text and leave the app bar, inputs and dialogs behind.
///
/// * **Palette.** [AppTheme] hardcodes the operational palette that the
///   dashboard and captain apps share. The rider app runs on the design file's
///   own tokens ([ClientPalette]), so every component theme that names a colour
///   is re-derived below. This is deliberately exhaustive rather than a bare
///   `colorScheme` swap: a component theme that names its own colour ignores
///   the scheme entirely, which is precisely how a half-themed app ends up with
///   Material's default violet switches sitting next to brand-blue buttons.
abstract final class ClientTheme {
  const ClientTheme._();

  /// [textThemeBuilder] overrides the ramp the whole theme is derived from.
  ///
  /// It exists for the captain app, which renders this exact design a step
  /// smaller (see `CaptainTheme`). It has to enter here rather than as a
  /// `copyWith(textTheme: …)` on the result, for the reason in the class doc:
  /// every component style below is derived from `base.textTheme`, so a later
  /// swap would resize the body text and leave the app bar, buttons, inputs,
  /// tabs and dialogs at the old size. Omit it and the rider ramp is used.
  static ThemeData light({TextTheme Function(ColorScheme)? textThemeBuilder}) =>
      _apply(
        AppTheme.lightTheme(
          textThemeBuilder: textThemeBuilder ?? AppTextThemes.cairoTextThemeFor,
        ),
        ClientPalette.light,
        Brightness.light,
      );

  static ThemeData dark({TextTheme Function(ColorScheme)? textThemeBuilder}) =>
      _apply(
        AppTheme.darkTheme(
          textThemeBuilder: textThemeBuilder ?? AppTextThemes.cairoTextThemeFor,
        ),
        ClientPalette.dark,
        Brightness.dark,
      );

  static ThemeData _apply(
    ThemeData base,
    ClientPalette p,
    Brightness brightness,
  ) {
    final scheme = _schemeOf(p, brightness);
    final text = base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
      decorationColor: p.text,
    );

    OutlineInputBorder field(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(ClientRadius.sm),
      borderSide: BorderSide(color: color, width: width),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      textTheme: text,
      primaryTextTheme: text,
      dividerColor: p.border,
      shadowColor: p.shadow,
      splashColor: p.primary.withValues(alpha: 0.08),
      highlightColor: p.primary.withValues(alpha: 0.05),
      disabledColor: p.textDisabled,
      hintColor: p.textMuted,
      iconTheme: IconThemeData(color: p.text),
      primaryIconTheme: IconThemeData(color: p.text),

      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: p.text),
        actionsIconTheme: IconThemeData(color: p.text),
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
      ),

      cardTheme: base.cardTheme.copyWith(
        color: p.surface,
        shadowColor: p.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          side: BorderSide(color: p.border),
        ),
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      // The design draws one CTA shape — a 14px radius, 15px vertical padding,
      // 700-weight label — and every filled/elevated button is that shape.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surface2,
          disabledForegroundColor: p.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.control),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surface2,
          disabledForegroundColor: p.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.control),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          disabledForegroundColor: p.textDisabled,
          // `1.5px` — the design's outline weight, a hair heavier than a
          // hairline so a ghost button still reads as an action.
          side: BorderSide(color: p.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.control),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          disabledForegroundColor: p.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.xs),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // Fields sit on `--surface-2` with a `--border` hairline at radius 12.
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: p.surface2,
        hintStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        floatingLabelStyle: text.bodySmall?.copyWith(color: p.primary),
        helperStyle: text.bodySmall?.copyWith(color: p.textMuted),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: field(p.border, 1),
        enabledBorder: field(p.border, 1),
        focusedBorder: field(p.primary, 1.5),
        disabledBorder: field(p.border, 1),
        errorBorder: field(p.danger, 1),
        focusedErrorBorder: field(p.danger, 1.5),
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.surface2,
        selectedColor: p.primary,
        disabledColor: p.surface2,
        side: BorderSide(color: p.border),
        labelStyle: text.labelMedium?.copyWith(color: p.text),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.onPrimary),
        checkmarkColor: p.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
      ),

      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: p.primary,
        unselectedLabelColor: p.textMuted,
        indicatorColor: p.primary,
        dividerColor: p.border,
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ClientRadius.sheet),
          ),
        ),
      ),

      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.lg),
        ),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: p.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.bg),
        actionTextColor: p.primaryStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.sm),
        ),
      ),

      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: p.text,
          borderRadius: BorderRadius.circular(ClientRadius.xs),
        ),
        textStyle: text.bodySmall?.copyWith(color: p.bg),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surface2,
        circularTrackColor: p.surface2,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.onPrimary : p.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primary : p.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primary : p.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : p.borderStrong,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.surface2,
        thumbColor: p.primary,
        overlayColor: p.primaryTint,
      ),

      listTileTheme: base.listTileTheme.copyWith(
        iconColor: p.textMuted,
        textColor: p.text,
        selectedColor: p.primary,
        selectedTileColor: p.primaryTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.sm),
        ),
      ),

      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primaryTint,
      ),

      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: text.bodyMedium?.copyWith(color: p.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClientRadius.md),
          side: BorderSide(color: p.border),
        ),
      ),
    );
  }

  static ColorScheme _schemeOf(ClientPalette p, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.primary2,
      onSecondary: p.onPrimary,
      secondaryContainer: p.primary2Tint,
      onSecondaryContainer: p.primary2,
      tertiary: p.warning,
      onTertiary: p.onPrimary,
      tertiaryContainer: p.warningBg,
      onTertiaryContainer: p.warning,
      error: p.danger,
      onError: p.onPrimary,
      errorContainer: p.dangerBg,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.bg,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface2,
      surfaceContainerHighest: p.surface2,
      surfaceTint: Colors.transparent,
      outline: p.border,
      outlineVariant: p.borderStrong,
      shadow: p.shadow,
      scrim: p.shadow,
      inverseSurface: p.text,
      onInverseSurface: p.bg,
      inversePrimary: p.primaryStrong,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_dark_colors.dart';
import 'app_light_colors.dart';
import 'colors.dart';
import 'app_surface_style.dart';
import 'tokens.dart';
import 'text_themes.dart';

class AppTheme {
  /// The unified light theme.
  ///
  /// Structurally identical to [darkTheme] — every component that can carry a
  /// colour is given one, from [AppLightColors]. It used to declare only ten
  /// component themes against the dark theme's thirty, so in light mode chips,
  /// tabs, switches, sliders, snack bars, tooltips, menus and the navigation
  /// rail all fell through to Material's own defaults. That is why light mode
  /// read as "a Flutter app" while dark mode read as a designed product: the
  /// default `Switch` is violet, the default `SnackBar` is a neutral charcoal,
  /// and neither has anything to do with this palette.
  static ThemeData lightTheme() {
    final colorScheme = lightColorSchemeFromPalette();
    final textTheme = AppTextThemes.textThemeFor(colorScheme);

    final hairline = BorderSide(color: colorScheme.outline);

    OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: side,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppLightColors.background,
      canvasColor: AppLightColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: colorScheme.outline,
      shadowColor: AppLightColors.shadow,
      splashColor: AppLightColors.primary.withAlpha(20),
      highlightColor: AppLightColors.primary.withAlpha(14),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        
        backgroundColor: AppLightColors.background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppLightColors.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          side: hairline,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      primaryIconTheme: IconThemeData(color: colorScheme.onSurface),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: AppLightColors.onSurfaceFaint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: AppLightColors.onSurfaceFaint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: AppLightColors.onSurfaceFaint,
          side: hairline,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppLightColors.primaryAccent,
          disabledForegroundColor: AppLightColors.onSurfaceFaint,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: AppLightColors.onSurfaceFaint,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppLightColors.primary,
        foregroundColor: AppLightColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: Colors.white24,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: inputBorder(hairline),
        enabledBorder: inputBorder(hairline),
        disabledBorder: inputBorder(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: inputBorder(
          const BorderSide(color: AppLightColors.primary, width: 2),
        ),
        errorBorder: inputBorder(
          const BorderSide(color: AppLightColors.dangerInk),
        ),
        focusedErrorBorder: inputBorder(
          const BorderSide(color: AppLightColors.dangerInk, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppLightColors.onSurfaceFaint,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppLightColors.onSurfaceMuted,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: AppLightColors.primaryAccent,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: AppLightColors.onSurfaceMuted,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppLightColors.dangerInk,
        ),
        prefixIconColor: AppLightColors.onSurfaceMuted,
        suffixIconColor: AppLightColors.onSurfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppLightColors.primary,
        selectionColor: AppLightColors.primary.withAlpha(50),
        selectionHandleColor: AppLightColors.primary,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppLightColors.scrim,
        dragHandleColor: colorScheme.outline,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppLightColors.scrim,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppLightColors.onSurfaceMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: AppLightColors.scrim,
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
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
          backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
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
          color: AppLightColors.onSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppLightColors.surface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppLightColors.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppLightColors.surface,
        ),
        actionTextColor: AppDarkColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppLightColors.primaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppLightColors.primaryAccent
                : AppLightColors.onSurfaceMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppLightColors.primaryAccent
                : AppLightColors.onSurfaceMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: AppLightColors.primaryAccent,
        unselectedItemColor: AppLightColors.onSurfaceMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppLightColors.primaryContainer,
        selectedIconTheme: const IconThemeData(
          color: AppLightColors.primaryAccent,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppLightColors.onSurfaceMuted,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppLightColors.primaryAccent,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppLightColors.onSurfaceMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppLightColors.primaryAccent,
        unselectedLabelColor: AppLightColors.onSurfaceMuted,
        indicatorColor: AppLightColors.primaryAccent,
        dividerColor: colorScheme.outline,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: AppLightColors.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withAlpha(120),
        checkmarkColor: AppLightColors.onPrimaryContainer,
        side: hairline,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppLightColors.onPrimaryContainer,
        ),
        iconTheme: const IconThemeData(
          color: AppLightColors.onSurfaceMuted,
          size: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppLightColors.danger,
        textColor: AppLightColors.onDanger,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppLightColors.onSurfaceMuted,
        textColor: colorScheme.onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: AppLightColors.onSurfaceMuted,
        ),
        selectedColor: AppLightColors.primaryAccent,
        selectedTileColor: AppLightColors.primary.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppLightColors.onPrimary
              : AppLightColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppLightColors.primary
              : AppLightColors.surfaceHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppLightColors.primary
              : AppLightColors.borderStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppLightColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppLightColors.onPrimary),
        side: const BorderSide(color: AppLightColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppLightColors.primary
              : AppLightColors.onSurfaceMuted,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppLightColors.primary,
        inactiveTrackColor: AppLightColors.surfaceHighest,
        thumbColor: AppLightColors.primary,
        overlayColor: AppLightColors.primary.withAlpha(38),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppLightColors.primary,
        linearTrackColor: AppLightColors.surfaceHighest,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: AppLightColors.surface,
      ),

      extensions: [AppSurfaceStyle.legacy(colorScheme)],
    );
  }

  /// The unified dark theme.
  ///
  /// Every component that can carry a colour is given one here, from
  /// [AppDarkColors]. That is the whole point of the pass: a screen inherits
  /// the system instead of re-deriving it, so nothing can drift by forgetting
  /// to opt in. Anything left to Material's defaults is where the old
  /// inconsistency crept back — an untinted `Chip`, a `SnackBar` in Material's
  /// own grey, a `Switch` in the default purple.
  static ThemeData darkTheme() {
    final colorScheme = darkColorSchemeFromPalette();
    final textTheme = AppTextThemes.textThemeFor(colorScheme);

    final hairline = BorderSide(color: colorScheme.outline);

    OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      borderSide: side,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDarkColors.background,
      canvasColor: AppDarkColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: colorScheme.outline,
      shadowColor: AppDarkColors.shadow,
      splashColor: AppDarkColors.primaryAccent.withAlpha(20),
      highlightColor: AppDarkColors.primaryAccent.withAlpha(14),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        
        backgroundColor: AppDarkColors.background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppDarkColors.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          side: hairline,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      primaryIconTheme: IconThemeData(color: colorScheme.onSurface),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: AppDarkColors.onSurfaceFaint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: AppDarkColors.onSurfaceFaint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: AppDarkColors.onSurfaceFaint,
          side: hairline,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDarkColors.primaryAccent,
          disabledForegroundColor: AppDarkColors.onSurfaceFaint,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: AppDarkColors.onSurfaceFaint,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppDarkColors.primary,
        foregroundColor: AppDarkColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: Colors.white24,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: inputBorder(hairline),
        enabledBorder: inputBorder(hairline),
        disabledBorder: inputBorder(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: inputBorder(
          
          const BorderSide(color: AppDarkColors.primaryAccent, width: 2),
        ),
        errorBorder: inputBorder(
          const BorderSide(color: AppDarkColors.dangerInk),
        ),
        focusedErrorBorder: inputBorder(
          const BorderSide(color: AppDarkColors.dangerInk, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.onSurfaceFaint,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.onSurfaceMuted,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.primaryAccent,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: AppDarkColors.onSurfaceMuted,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppDarkColors.dangerInk,
        ),
        prefixIconColor: AppDarkColors.onSurfaceMuted,
        suffixIconColor: AppDarkColors.onSurfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppDarkColors.primaryAccent,
        selectionColor: AppDarkColors.primaryAccent.withAlpha(60),
        selectionHandleColor: AppDarkColors.primaryAccent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppDarkColors.scrim,
        dragHandleColor: colorScheme.outline,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppDarkColors.scrim,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.onSurfaceMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: AppDarkColors.scrim,
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppDarkColors.surfaceRaised,
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
          backgroundColor: const WidgetStatePropertyAll(
            AppDarkColors.surfaceRaised,
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
          color: AppDarkColors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.fromBorderSide(hairline),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppDarkColors.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        actionTextColor: AppDarkColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: hairline,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppDarkColors.primaryAccent.withAlpha(38),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppDarkColors.primaryAccent
                : AppDarkColors.onSurfaceMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppDarkColors.primaryAccent
                : AppDarkColors.onSurfaceMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: AppDarkColors.primaryAccent,
        unselectedItemColor: AppDarkColors.onSurfaceMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppDarkColors.primaryAccent.withAlpha(38),
        selectedIconTheme: const IconThemeData(
          color: AppDarkColors.primaryAccent,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppDarkColors.onSurfaceMuted,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppDarkColors.primaryAccent,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppDarkColors.onSurfaceMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppDarkColors.primaryAccent,
        unselectedLabelColor: AppDarkColors.onSurfaceMuted,
        indicatorColor: AppDarkColors.primaryAccent,
        dividerColor: colorScheme.outline,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: AppDarkColors.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withAlpha(120),
        checkmarkColor: AppDarkColors.onPrimaryContainer,
        side: hairline,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppDarkColors.onPrimaryContainer,
        ),
        iconTheme: const IconThemeData(
          color: AppDarkColors.onSurfaceMuted,
          size: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppDarkColors.danger,
        textColor: AppDarkColors.onDanger,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppDarkColors.onSurfaceMuted,
        textColor: colorScheme.onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: AppDarkColors.onSurfaceMuted,
        ),
        selectedColor: AppDarkColors.primaryAccent,
        selectedTileColor: AppDarkColors.primaryAccent.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppDarkColors.onPrimary
              : AppDarkColors.onSurfaceMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppDarkColors.primary
              : AppDarkColors.surfaceHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppDarkColors.primary
              : colorScheme.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppDarkColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppDarkColors.onPrimary),
        side: hairline,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppDarkColors.primaryAccent
              : AppDarkColors.onSurfaceMuted,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppDarkColors.primary,
        inactiveTrackColor: AppDarkColors.surfaceHighest,
        thumbColor: AppDarkColors.primaryAccent,
        overlayColor: AppDarkColors.primaryAccent.withAlpha(38),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppDarkColors.primaryAccent,
        linearTrackColor: AppDarkColors.surfaceHighest,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: AppDarkColors.surface,
      ),

      extensions: [AppSurfaceStyle.legacy(colorScheme)],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';

abstract final class ClientColors {
  
  /// Primary EWT brand color.
  /// Use for primary actions, active navigation, selected states, links,
  /// focused controls, and important interactive elements.
  static const Color primary = Color(0xFF2563EB);

  /// Hover state for primary interactive elements.
  static const Color primaryHover = Color(0xFF1D4ED8);

  /// Pressed / strongest primary state.
  static const Color primaryPressed = Color(0xFF1E40AF);

  /// Very light blue surface for selected and highlighted elements.
  static const Color primaryLight = Color(0xFFEFF6FF);

  /// Light blue container for active navigation, selected cards,
  /// informational surfaces, and soft brand highlights.
  static const Color primaryContainer = Color(0xFFDBEAFE);

  /// Muted blue for disabled or low-emphasis brand elements.
  static const Color primaryMuted = Color(0xFF93C5FD);

  /// Text and icons displayed on primary blue.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text and icons displayed on primary containers.
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  /// Secondary blue.
  ///
  /// Keep within the EWT blue family.
  /// Do not use this as a competing brand color.
  static const Color secondary = Color(0xFF3B82F6);

  /// Soft accent blue.
  ///
  /// Use sparingly for secondary interactive elements.
  /// EWT should remain visually centered around the primary blue palette.
  static const Color accent = Color(0xFF60A5FA);

  static const Color darkPrimary = AppDarkColors.primaryAccent;

  /// Dark-mode fill used for primary buttons and solid interactive surfaces.
  static const Color darkPrimaryFill = AppDarkColors.primary;

  static const Color darkPrimaryStrong = AppDarkColors.primaryAccent;

  static const Color darkPrimaryLight = AppDarkColors.primaryContainer;

  /// Keep secondary brand color inside the blue family.
  static const Color darkSecondary = AppDarkColors.primaryAccent;

  /// Keep the dark theme fully aligned with the EWT blue identity.
  static const Color darkAccent = AppDarkColors.primaryAccent;

  /// Subtle EWT blue gradient.
  ///
  /// Use only for large hero surfaces or special branded areas.
  /// Avoid using gradients for standard buttons, KPI cards, tables,
  /// status badges, or navigation.
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkPrimaryGradient = AppDarkColors.brandGradient;

  /// Professional blue hero gradient.
  ///
  /// Keep the palette limited to two blue tones.
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkHeroGradient = LinearGradient(
    colors: [
      AppDarkColors.background,
      AppDarkColors.primaryContainer,
      AppDarkColors.primary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Active trip — EWT primary blue.
  static const Color journeyCyan = Color(0xFF2563EB);

  /// Soft blue background for active trip badges.
  static const Color journeyCyanLight = Color(0xFFEFF6FF);

  /// Text and icon color on active trip surfaces.
  static const Color onJourneyCyan = Color(0xFF1D4ED8);

  /// Strong blue used for active trip indicators and filled surfaces.
  static const Color journeyCyanStrong = Color(0xFF1D4ED8);

  /// Amber is reserved for attention-required states.
  static const Color journeyAmber = Color(0xFFD97706);

  /// Soft amber background.
  static const Color journeyAmberLight = Color(0xFFFFFBEB);

  /// Text and icon color on amber surfaces.
  static const Color onJourneyAmber = Color(0xFF92400E);

  /// Strong amber for emphasis.
  static const Color journeyAmberStrong = Color(0xFFB45309);

  /// Red is reserved for errors, cancellation, and destructive states.
  static const Color journeyRed = Color(0xFFDC2626);

  /// Soft red background.
  static const Color journeyRedLight = Color(0xFFFEF2F2);

  /// Text and icon color on red surfaces.
  static const Color onJourneyRed = Color(0xFF991B1B);

  /// Strong red for destructive actions and important error indicators.
  static const Color journeyRedStrong = Color(0xFFB91C1C);

  /// Neutral slate for completed trips and historical states.
  static const Color journeySlate = Color(0xFF64748B);

  /// Soft neutral background.
  static const Color journeySlateLight = Color(0xFFF1F5F9);

  /// Text and icon color on neutral surfaces.
  static const Color onJourneySlate = Color(0xFF334155);

  /// Gold is reserved exclusively for ratings and stars.
  ///
  /// Do not use this color for warnings.
  static const Color rating = Color(0xFFF59E0B);

  @Deprecated('Purple is no longer part of the EWT color system.')
  static const Color journeyPurple = primary;

  @Deprecated('Purple is no longer part of the EWT color system.')
  static const Color journeyPurpleLight = primaryLight;

  @Deprecated('Purple is no longer part of the EWT color system.')
  static const Color onJourneyPurple = onPrimaryContainer;

  /// Available seat background.
  static const Color seatAvailable = Color(0xFFEFF6FF);

  /// Available seat border.
  static const Color seatAvailableBorder = Color(0xFFBFDBFE);

  /// Text and icon color for available seats.
  static const Color onSeatAvailable = Color(0xFF1D4ED8);

  static const Color _darkSeatAvailable = Color(0xFF172554);

  static const Color _darkSeatAvailableBorder = AppDarkColors.primaryContainer;

  static const Color _darkOnSeatAvailable = AppDarkColors.primaryAccent;

  /// Main text color.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Secondary text color.
  static const Color textSecondary = Color(0xFF475569);

  /// Supporting / metadata text.
  static const Color textTertiary = Color(0xFF64748B);

  /// Disabled text.
  static const Color textDisabled = Color(0xFF94A3B8);

  /// Text displayed on dark or primary surfaces.
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Main page background.
  ///
  /// Slightly tinted instead of pure white to create a professional SaaS look.
  static const Color background = Color(0xFFF8FAFC);

  /// Main card and elevated surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle page and section surface.
  static const Color surfaceSubtle = Color(0xFFF8FAFC);

  /// Muted surface used for secondary areas.
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  /// Raised cards and interactive surfaces.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Default border.
  static const Color border = Color(0xFFE2E8F0);

  /// Strong border for inputs and emphasized separators.
  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color _darkBackground = AppDarkColors.background;

  static const Color _darkSurface = AppDarkColors.surface;

  static const Color _darkSurfaceSubtle = AppDarkColors.surfaceLow;

  static const Color _darkSurfaceMuted = AppDarkColors.surfaceHighest;

  static const Color _darkSurfaceRaised = AppDarkColors.surfaceRaised;

  static const Color _darkBorder = AppDarkColors.border;

  static const Color _darkBorderStrong = AppDarkColors.borderStrong;

  static const Color _darkTextPrimary = AppDarkColors.onSurface;

  static const Color _darkTextSecondary = AppDarkColors.onSurfaceMuted;

  static const Color _darkTextTertiary = AppDarkColors.onSurfaceFaint;

  static Color surfaceFor(BuildContext context) =>
      _isDark(context) ? _darkSurface : surface;

  static Color backgroundFor(BuildContext context) =>
      _isDark(context) ? _darkBackground : background;

  static Color surfaceSubtleFor(BuildContext context) =>
      _isDark(context) ? _darkSurfaceSubtle : surfaceSubtle;

  static Color surfaceMutedFor(BuildContext context) =>
      _isDark(context) ? _darkSurfaceMuted : surfaceMuted;

  static Color surfaceRaisedFor(BuildContext context) =>
      _isDark(context) ? _darkSurfaceRaised : surfaceRaised;

  static Color borderFor(BuildContext context) =>
      _isDark(context) ? _darkBorder : border;

  static Color borderStrongFor(BuildContext context) =>
      _isDark(context) ? _darkBorderStrong : borderStrong;

  static Gradient primaryGradientFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryGradient : primaryGradient;

  static Gradient heroGradientFor(BuildContext context) =>
      _isDark(context) ? darkHeroGradient : heroGradient;

  /// First color of the hero gradient.
  static Color heroTopFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.background : const Color(0xFF1E40AF);

  static Color textPrimaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextPrimary : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextSecondary : textSecondary;

  static Color textTertiaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextTertiary : textTertiary;

  /// Brand blue used as text, icon, border, focus ring, or indicator.
  static Color primaryFor(BuildContext context) =>
      _isDark(context) ? darkPrimary : primary;

  /// Brand blue used as a solid fill.
  static Color primaryFillFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryFill : primary;

  /// Soft brand blue container.
  static Color primaryContainerFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryLight : primaryContainer;

  /// Text and icons displayed on the primary blue container.
  static Color onPrimaryContainerFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onPrimaryContainer : onPrimaryContainer;

  static Color seatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailable : seatAvailable;

  static Color seatAvailableBorderFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailableBorder : seatAvailableBorder;

  static Color onSeatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkOnSeatAvailable : onSeatAvailable;

  static Color shadowFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.shadow : const Color(0xFF0F172A);

  /// Shadow opacity scale.
  ///
  /// Dark mode requires stronger shadows to maintain visual separation
  /// between surfaces.
  static double shadowAlphaScaleFor(BuildContext context) =>
      _isDark(context) ? 5.0 : 1.0;

  /// Active trip.
  ///
  /// Uses EWT Blue instead of Cyan or Green.
  static Color journeyCyanFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.primaryAccent : journeyCyan;

  /// Departing soon / attention required.
  static Color journeyAmberFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.warningInk : journeyAmber;

  /// Cancelled / error.
  static Color journeyRedFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.dangerInk : journeyRed;

  /// Completed / inactive.
  static Color journeySlateFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onSurfaceMuted : journeySlate;

  /// Purple has been removed from the EWT theme.
  ///
  /// Kept as a compatibility alias only.
  @Deprecated('Purple is no longer part of the EWT color system.')
  static Color journeyPurpleFor(BuildContext context) => primaryFor(context);

  static Color journeyCyanLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.primaryContainer : journeyCyanLight;

  static Color journeyAmberLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.warningContainer : journeyAmberLight;

  static Color journeyRedLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.dangerContainer : journeyRedLight;

  static Color journeySlateLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.neutralContainer : journeySlateLight;

  /// Purple has been removed from the EWT theme.
  @Deprecated('Purple is no longer part of the EWT color system.')
  static Color journeyPurpleLightFor(BuildContext context) =>
      primaryContainerFor(context);

  static Color onJourneyCyanFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onPrimaryContainer : onJourneyCyan;

  static Color onJourneyAmberFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onWarningContainer : onJourneyAmber;

  static Color onJourneyRedFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onDangerContainer : onJourneyRed;

  static Color onJourneySlateFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onNeutralContainer : onJourneySlate;

  /// Purple has been removed from the EWT theme.
  @Deprecated('Purple is no longer part of the EWT color system.')
  static Color onJourneyPurpleFor(BuildContext context) =>
      onPrimaryContainerFor(context);

  static Color ratingFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.rating : rating;

  static ({Color bg, Color fg, Color label}) journeyBadge(
    ClientJourneyStatus status,
  ) {
    return switch (status) {
      
      ClientJourneyStatus.active => (
        bg: journeyCyanLight,
        fg: onJourneyCyan,
        label: journeyCyan,
      ),

      ClientJourneyStatus.upcoming => (
        bg: primaryLight,
        fg: onPrimaryContainer,
        label: primary,
      ),

      ClientJourneyStatus.departing => (
        bg: journeyAmberLight,
        fg: onJourneyAmber,
        label: journeyAmber,
      ),

      ClientJourneyStatus.completed => (
        bg: journeySlateLight,
        fg: onJourneySlate,
        label: journeySlate,
      ),

      ClientJourneyStatus.cancelled => (
        bg: journeyRedLight,
        fg: onJourneyRed,
        label: journeyRed,
      ),
    };
  }

  static ({Color bg, Color fg, Color label}) journeyBadgeFor(
    BuildContext context,
    ClientJourneyStatus status,
  ) {
    if (!_isDark(context)) {
      return journeyBadge(status);
    }

    return switch (status) {
      
      ClientJourneyStatus.active => (
        bg: AppDarkColors.primaryContainer,
        fg: AppDarkColors.onPrimaryContainer,
        label: AppDarkColors.primaryAccent,
      ),

      ClientJourneyStatus.upcoming => (
        bg: AppDarkColors.primaryContainer,
        fg: AppDarkColors.onPrimaryContainer,
        label: AppDarkColors.primaryAccent,
      ),

      ClientJourneyStatus.departing => (
        bg: AppDarkColors.warningContainer,
        fg: AppDarkColors.onWarningContainer,
        label: AppDarkColors.warningInk,
      ),

      ClientJourneyStatus.completed => (
        bg: AppDarkColors.neutralContainer,
        fg: AppDarkColors.onNeutralContainer,
        label: AppDarkColors.onSurfaceMuted,
      ),

      ClientJourneyStatus.cancelled => (
        bg: AppDarkColors.dangerContainer,
        fg: AppDarkColors.onDangerContainer,
        label: AppDarkColors.dangerInk,
      ),
    };
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

enum ClientJourneyStatus { active, upcoming, departing, completed, cancelled }

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// The dashboard's chrome tokens — the surfaces a management console has and
/// the mobile apps do not: a sidebar, a top bar, data tables, KPI tiles.
///
/// Everything here is derived from [DashboardLightColors] / [DashboardDarkColors]
/// — the EWT console's own warm-paper / slate palette, kept deliberately apart
/// from [AppLightColors]/[AppDarkColors] (the client and captain apps' cool
/// slate palette). That is the whole contract: the dashboard gets its own
/// *components* and, since the EWT redesign, its own *palette* — but every call
/// site in the dashboard still goes through this one indirection layer, so
/// nothing needed to change at the ~250 places that already read it.
///
/// [AppStatusTone] / [AppStatusStyle] (the six-role status vocabulary) stay the
/// **shared** types from `core/theme/tokens.dart` — only the values [status]
/// resolves them to change, via [DashboardStatusPalette]. Redefining either
/// type here would collide with the shared ones at every call site that
/// imports both.
///
/// The ladder, applied to console chrome:
///
/// | Surface        | Light             | Dark                |
/// |----------------|-------------------|---------------------|
/// | Page           | `background`      | `background`        |
/// | Sidebar        | `surfaceLow`      | `surfaceLow`        |
/// | Top bar        | `surface`         | `surface`           |
/// | Panel / card   | `surface`         | `surface`           |
/// | Table header   | `surfaceHighest`  | `surfaceHighest`    |
/// | Nested tile    | `surfaceRaised`   | `surfaceRaised`     |
abstract final class DashboardColors {
  const DashboardColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// The page behind every module.
  static Color page(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.background
      : DashboardLightColors.background;

  /// The left navigation rail. One step off the page so the shell frames the
  /// content without becoming a card in its own right.
  static Color sidebar(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.surfaceLow
      : DashboardLightColors.surfaceLow;

  /// The fill behind the selected nav item. Warm/lifted, not brand-tinted — the
  /// brand is spent on the 2px inline edge ([navSelectedEdge]) instead, so the
  /// sidebar never reads as a wall of blue.
  static Color sidebarSelected(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.navSelected
      : DashboardLightColors.navSelected;

  /// The 2px inline edge marking the selected nav row.
  static Color navSelectedEdge(BuildContext context) => accentFill(context);

  /// Ink for the selected nav item's icon and label.
  static Color sidebarSelectedInk(BuildContext context) => ink(context);

  /// Ink for an unselected nav item.
  static Color sidebarInk(BuildContext context) => mutedInk(context);

  /// The group headers ("التشغيل", "المالية", …) that split the nav list.
  static Color sidebarSectionInk(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.onSurfaceFaint
      : DashboardLightColors.onSurfaceFaint;

  /// The bar across the top of the content area.
  static Color topBar(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.surface
      : DashboardLightColors.surface;

  /// Panels, cards, dialogs, sheets.
  static Color panel(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.surface
      : DashboardLightColors.surface;

  /// A tile nested inside a panel, which cannot repeat its parent's colour.
  static Color nested(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.surfaceRaised
      : DashboardLightColors.surfaceRaised;

  /// Content cut *into* a surface — chart plot areas, map backdrops, the
  /// unfilled part of a progress track.
  static Color well(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.canvas
      : DashboardLightColors.canvas;

  /// The brand sweep behind a hero lockup.
  static LinearGradient heroGradient(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.brandGradient
      : DashboardLightColors.brandGradient;

  /// Ink on [heroGradient]. White in both themes.
  static Color onHero(BuildContext context) => DashboardLightColors.onFilled;

  static Color border(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.border
      : DashboardLightColors.border;

  /// A line *inside* an already-bordered surface — the rule between two table
  /// rows, a separator within a panel.
  static Color divider(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.borderSubtle
      : DashboardLightColors.borderSubtle;

  /// A border carrying weight on its own: a selected tile's outline, the edge
  /// of a focused filter.
  static Color borderStrong(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.borderStrong
      : DashboardLightColors.borderStrong;

  static Color ink(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.onSurface
      : DashboardLightColors.onSurface;

  /// Column labels, captions, secondary values.
  static Color mutedInk(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.onSurfaceMuted
      : DashboardLightColors.onSurfaceMuted;

  /// Placeholders and disabled text. Below the AA floor by design.
  static Color faintInk(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.onSurfaceFaint
      : DashboardLightColors.onSurfaceFaint;

  /// Brand blue as **ink** — a link, an active sort arrow, a tinted icon.
  static Color accentInk(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.primaryAccent
      : DashboardLightColors.primaryAccent;

  /// Brand blue as a **fill** — a primary action, a selected chip. Carries
  /// white text in both themes.
  static Color accentFill(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.primary
      : DashboardLightColors.primary;

  /// The sticky header band of a data table.
  static Color tableHeader(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.surfaceHighest
      : DashboardLightColors.surfaceHighest;

  /// The hover wash on a table row. Deliberately an alpha over the panel rather
  /// than a solid tone: a row can sit on a card or on the page, and the wash
  /// has to read the same on both.
  static Color tableRowHover(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.primaryAccent.withAlpha(20)
      : DashboardLightColors.primary.withAlpha(14);

  /// The hairline between two table rows.
  static Color tableDivider(BuildContext context) => divider(context);

  /// A panel lifted off the page.
  static List<BoxShadow> panelShadow(BuildContext context) => _isDark(context)
      ? DashboardDarkColors.softShadow
      : DashboardLightColors.softShadow;

  /// A floating element — a menu, a dialog, a sticky action bar.
  static List<BoxShadow> floatingShadow(BuildContext context) =>
      _isDark(context)
      ? DashboardDarkColors.floatingShadow
      : DashboardLightColors.floatingShadow;

  /// The brightness-correct colours for one of the six semantic status roles,
  /// resolved against the dashboard's own palette.
  ///
  /// This is the accessor every badge, chip and pill in the dashboard should
  /// use. [AppStatusTone] / [AppStatusStyle] are the shared types from
  /// `core/theme/tokens.dart`; only the underlying colour values are the
  /// console's own.
  ///
  /// Returns `tint` (the container fill), `ink` (text/icons on that fill) and
  /// `accent` (the standalone mark — a dot, a border, a bare label with no
  /// container behind it).
  static AppStatusStyle status(BuildContext context, AppStatusTone tone) =>
      DashboardStatusPalette.resolve(Theme.of(context).brightness, tone);

  /// The border/line colour for a status badge of [tone] — the 6px-rect
  /// [DashboardStatusChip]'s edge. Kept apart from [AppStatusStyle] (which has
  /// no `line` field) rather than widening the shared type for one console-only
  /// badge shape.
  static Color statusLine(BuildContext context, AppStatusTone tone) {
    final dark = _isDark(context);
    return switch (tone) {
      AppStatusTone.success =>
        dark
            ? DashboardDarkColors.successLine
            : DashboardLightColors.successLine,
      AppStatusTone.warning =>
        dark
            ? DashboardDarkColors.warningLine
            : DashboardLightColors.warningLine,
      AppStatusTone.error =>
        dark ? DashboardDarkColors.dangerLine : DashboardLightColors.dangerLine,
      AppStatusTone.info =>
        dark
            ? DashboardDarkColors.primaryLine
            : DashboardLightColors.primaryLine,
      AppStatusTone.neutral => border(context),
      AppStatusTone.special =>
        dark
            ? DashboardDarkColors.specialLine
            : DashboardLightColors.specialLine,
    };
  }

  /// The tinted background for a tile keyed to [accent].
  static Color kpiTint(BuildContext context, Color accent) =>
      accent.withAlpha(_isDark(context) ? 38 : 40);

  /// The border for a tile keyed to [accent].
  static Color kpiBorder(BuildContext context, Color accent) =>
      accent.withAlpha(_isDark(context) ? 90 : 115);
}

/// Resolves the shared [AppStatusTone] against the dashboard's own
/// [DashboardLightColors]/[DashboardDarkColors] instead of the client/captain
/// palette — the console-scoped twin of [AppStatusStyle.resolve].
abstract final class DashboardStatusPalette {
  const DashboardStatusPalette._();

  static AppStatusStyle resolve(Brightness brightness, AppStatusTone tone) =>
      brightness == Brightness.dark ? _dark(tone) : _light(tone);

  static AppStatusStyle _dark(AppStatusTone tone) => switch (tone) {
    AppStatusTone.success => const AppStatusStyle(
      tint: DashboardDarkColors.successContainer,
      ink: DashboardDarkColors.onSuccessContainer,
      accent: DashboardDarkColors.successInk,
      fill: DashboardDarkColors.success,
      onFill: DashboardDarkColors.background,
    ),
    AppStatusTone.warning => const AppStatusStyle(
      tint: DashboardDarkColors.warningContainer,
      ink: DashboardDarkColors.onWarningContainer,
      accent: DashboardDarkColors.warningInk,
      fill: DashboardDarkColors.warning,
      onFill: DashboardDarkColors.background,
    ),
    AppStatusTone.error => const AppStatusStyle(
      tint: DashboardDarkColors.dangerContainer,
      ink: DashboardDarkColors.onDangerContainer,
      accent: DashboardDarkColors.dangerInk,
      fill: DashboardDarkColors.danger,
      onFill: DashboardDarkColors.onDanger,
    ),
    AppStatusTone.info => const AppStatusStyle(
      tint: DashboardDarkColors.infoContainer,
      ink: DashboardDarkColors.onInfoContainer,
      accent: DashboardDarkColors.primaryAccent,
      fill: DashboardDarkColors.primary,
      onFill: DashboardDarkColors.onPrimary,
    ),
    AppStatusTone.neutral => const AppStatusStyle(
      tint: DashboardDarkColors.neutralContainer,
      ink: DashboardDarkColors.onNeutralContainer,
      accent: DashboardDarkColors.onSurfaceMuted,
      fill: DashboardDarkColors.surfaceHighest,
      onFill: DashboardDarkColors.onSurface,
    ),
    AppStatusTone.special => const AppStatusStyle(
      tint: DashboardDarkColors.specialContainer,
      ink: DashboardDarkColors.onSpecialContainer,
      accent: DashboardDarkColors.special,
      fill: DashboardDarkColors.special,
      onFill: DashboardDarkColors.background,
    ),
  };

  static AppStatusStyle _light(AppStatusTone tone) => switch (tone) {
    AppStatusTone.success => const AppStatusStyle(
      tint: DashboardLightColors.successContainer,
      ink: DashboardLightColors.onSuccessContainer,
      accent: DashboardLightColors.successInk,
      fill: DashboardLightColors.success,
      onFill: DashboardLightColors.onFilled,
    ),
    AppStatusTone.warning => const AppStatusStyle(
      tint: DashboardLightColors.warningContainer,
      ink: DashboardLightColors.onWarningContainer,
      accent: DashboardLightColors.warningInk,
      fill: DashboardLightColors.warning,
      onFill: DashboardLightColors.onFilled,
    ),
    AppStatusTone.error => const AppStatusStyle(
      tint: DashboardLightColors.dangerContainer,
      ink: DashboardLightColors.onDangerContainer,
      accent: DashboardLightColors.dangerInk,
      fill: DashboardLightColors.danger,
      onFill: DashboardLightColors.onDanger,
    ),
    AppStatusTone.info => const AppStatusStyle(
      tint: DashboardLightColors.infoContainer,
      ink: DashboardLightColors.onInfoContainer,
      accent: DashboardLightColors.primaryAccent,
      fill: DashboardLightColors.primary,
      onFill: DashboardLightColors.onPrimary,
    ),
    AppStatusTone.neutral => const AppStatusStyle(
      tint: DashboardLightColors.neutralContainer,
      ink: DashboardLightColors.onNeutralContainer,
      accent: DashboardLightColors.onSurfaceMuted,
      fill: DashboardLightColors.surfaceHighest,
      onFill: DashboardLightColors.onSurface,
    ),
    AppStatusTone.special => const AppStatusStyle(
      tint: DashboardLightColors.specialContainer,
      ink: DashboardLightColors.onSpecialContainer,
      accent: DashboardLightColors.special,
      fill: DashboardLightColors.special,
      onFill: DashboardLightColors.onFilled,
    ),
  };
}

/// `context.status(AppStatusTone.warning).ink` — the short form of
/// [DashboardColors.status].
///
/// Worth an extension because status colours are the single most repeated
/// lookup in the dashboard (badges, chips, table cells, banners, KPI tiles, and
/// every module has them). Spelling the resolver out in full at ~250 call sites
/// buries the one thing that matters — which of the six roles this is.
extension DashboardStatusContext on BuildContext {
  AppStatusStyle status(AppStatusTone tone) =>
      DashboardColors.status(this, tone);
}

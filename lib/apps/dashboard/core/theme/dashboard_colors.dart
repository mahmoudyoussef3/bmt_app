import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// The dashboard's chrome tokens — the surfaces a management console has and
/// the mobile apps do not: a sidebar, a top bar, data tables, KPI tiles.
///
/// Everything here is derived from [AppLightColors] / [AppDarkColors], the same
/// two palettes the client and captain apps are drawn in. Nothing in this file
/// introduces a hue; it only decides which tier of the shared surface ladder
/// each piece of dashboard furniture sits on. That is the whole contract: the
/// dashboard gets its own *components*, not its own *colours*.
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
///
/// Note that the *role* column is identical across both themes even though the
/// lightness ordering is not — see [AppLightColors] for why the light ladder
/// descends where the dark one climbs.
abstract final class DashboardColors {
  const DashboardColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// The page behind every module.
  static Color page(BuildContext context) =>
      _isDark(context) ? AppDarkColors.background : AppLightColors.background;

  /// The left navigation rail. One step off the page so the shell frames the
  /// content without becoming a card in its own right.
  static Color sidebar(BuildContext context) =>
      _isDark(context) ? AppDarkColors.surfaceLow : AppLightColors.surfaceLow;

  /// The fill behind the selected nav item.
  static Color sidebarSelected(BuildContext context) => _isDark(context)
      ? AppDarkColors.primaryContainer
      : AppLightColors.primaryContainer;

  /// Ink for the selected nav item's icon and label.
  static Color sidebarSelectedInk(BuildContext context) => _isDark(context)
      ? AppDarkColors.onPrimaryContainer
      : AppLightColors.onPrimaryContainer;

  /// Ink for an unselected nav item.
  static Color sidebarInk(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onSurface : AppLightColors.onSurface;

  /// The group headers ("التشغيل", "المالية", …) that split the nav list.
  static Color sidebarSectionInk(BuildContext context) => _isDark(context)
      ? AppDarkColors.onSurfaceMuted
      : AppLightColors.onSurfaceMuted;

  /// The bar across the top of the content area.
  static Color topBar(BuildContext context) =>
      _isDark(context) ? AppDarkColors.surface : AppLightColors.surface;

  /// Panels, cards, dialogs, sheets.
  static Color panel(BuildContext context) =>
      _isDark(context) ? AppDarkColors.surface : AppLightColors.surface;

  /// A tile nested inside a panel, which cannot repeat its parent's colour.
  static Color nested(BuildContext context) => _isDark(context)
      ? AppDarkColors.surfaceRaised
      : AppLightColors.surfaceRaised;

  /// Content cut *into* a surface — chart plot areas, map backdrops, the
  /// unfilled part of a progress track.
  static Color well(BuildContext context) =>
      _isDark(context) ? AppDarkColors.canvas : AppLightColors.canvas;

  /// The brand sweep behind the home banner and any other hero lockup.
  ///
  /// The same two stops the client app's hero and the captain's profile header
  /// use. The home banner used to be a flat `#0F2747` navy that appeared
  /// nowhere else in the product — near enough to the brand blue to look like a
  /// mistake, far enough to break the identity on the first screen an operator
  /// sees.
  static LinearGradient heroGradient(BuildContext context) => _isDark(context)
      ? AppDarkColors.brandGradient
      : AppLightColors.brandGradient;

  /// Ink on [heroGradient]. White in both themes — both sweeps are deep enough
  /// to carry it at AA.
  static Color onHero(BuildContext context) => AppLightColors.onFilled;

  static Color border(BuildContext context) =>
      _isDark(context) ? AppDarkColors.border : AppLightColors.border;

  /// A line *inside* an already-bordered surface — the rule between two table
  /// rows, a separator within a panel.
  static Color divider(BuildContext context) => _isDark(context)
      ? AppDarkColors.borderSubtle
      : AppLightColors.borderSubtle;

  /// A border carrying weight on its own: a selected tile's outline, the edge
  /// of a focused filter.
  static Color borderStrong(BuildContext context) => _isDark(context)
      ? AppDarkColors.borderStrong
      : AppLightColors.borderStrong;

  static Color ink(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onSurface : AppLightColors.onSurface;

  /// Column labels, captions, secondary values.
  static Color mutedInk(BuildContext context) => _isDark(context)
      ? AppDarkColors.onSurfaceMuted
      : AppLightColors.onSurfaceMuted;

  /// Placeholders and disabled text. Below the AA floor by design.
  static Color faintInk(BuildContext context) => _isDark(context)
      ? AppDarkColors.onSurfaceFaint
      : AppLightColors.onSurfaceFaint;

  /// Brand blue as **ink** — a link, an active sort arrow, a tinted icon.
  static Color accentInk(BuildContext context) => _isDark(context)
      ? AppDarkColors.primaryAccent
      : AppLightColors.primaryAccent;

  /// Brand blue as a **fill** — a primary action, a selected chip. Carries
  /// white text in both themes.
  static Color accentFill(BuildContext context) =>
      _isDark(context) ? AppDarkColors.primary : AppLightColors.primary;

  /// The sticky header band of a data table.
  static Color tableHeader(BuildContext context) => _isDark(context)
      ? AppDarkColors.surfaceHighest
      : AppLightColors.surfaceHighest;

  /// The hover wash on a table row. Deliberately an alpha over the panel rather
  /// than a solid tone: a row can sit on a card or on the page, and the wash
  /// has to read the same on both.
  static Color tableRowHover(BuildContext context) => _isDark(context)
      ? AppDarkColors.primaryAccent.withAlpha(20)
      : AppLightColors.primary.withAlpha(14);

  /// The hairline between two table rows.
  static Color tableDivider(BuildContext context) => divider(context);

  /// A panel lifted off the page.
  static List<BoxShadow> panelShadow(BuildContext context) =>
      _isDark(context) ? AppDarkColors.softShadow : AppLightColors.softShadow;

  /// A floating element — a menu, a dialog, a sticky action bar.
  static List<BoxShadow> floatingShadow(BuildContext context) =>
      _isDark(context)
      ? AppDarkColors.floatingShadow
      : AppLightColors.floatingShadow;

  /// The brightness-correct colours for one of the six semantic status roles.
  ///
  /// This is the accessor every badge, chip and pill in the dashboard should
  /// use. The bare [AppStatusColors] constants it replaces are **light-mode
  /// values only** — a `#CFFAFE` pill on a slate page is a lit panel in a dark
  /// room — and they were being read unresolved at ~250 call sites, which is
  /// why status badges were the one thing that never survived a theme switch.
  ///
  /// Returns `tint` (the container fill), `ink` (text/icons on that fill) and
  /// `accent` (the standalone mark — a dot, a border, a bare label with no
  /// container behind it).
  static AppStatusStyle status(BuildContext context, AppStatusTone tone) =>
      AppStatusStyle.of(context, tone);

  /// The tinted background for a KPI tile keyed to [accent].
  ///
  /// A flat alpha does not work across both themes: 16/255 of a mid-tone over
  /// white is a visible tint, while the same over slate is nothing. Dark mode
  /// needs roughly twice the opacity to read as the same tile.
  ///
  /// Light was `20` — a KPI tile carries no shadow (nesting a card inside the
  /// header/panel card it already sits in is the one thing this system
  /// avoids), so tint and border are its *only* signal. At `20` four tiles in
  /// a row were indistinguishable from the page behind them.
  ///
  /// `40`, not `32`: several of the accents this is called with (see
  /// `DashboardChartPalette`'s `positive`/`active`/`neutral`) are `onXContainer`
  /// *ink* tones — deliberately dark, low-chroma colours meant to sit as text on
  /// their own light container, not to seed one. Alpha-blending a low-chroma
  /// dark colour toward white moves mostly through grey; a vivid accent like
  /// [ColorScheme.primary] or the warning/danger tones read fine at a lower
  /// alpha, but the muted inks needed the extra room to still land as colour
  /// rather than a slightly warm or cool grey. Checked across four KPI rows
  /// (Home, Fleet, Finance, Customers) side by side.
  static Color kpiTint(BuildContext context, Color accent) =>
      accent.withAlpha(_isDark(context) ? 38 : 40);

  /// The border for a KPI tile keyed to [accent].
  static Color kpiBorder(BuildContext context, Color accent) =>
      accent.withAlpha(_isDark(context) ? 90 : 115);
}

/// `context.status(AppStatusTone.warning).ink` — the short form of
/// [DashboardColors.status].
///
/// Worth an extension because status colours are the single most repeated
/// lookup in the dashboard (badges, chips, table cells, banners, KPI tiles, and
/// every module has them). Spelling the resolver out in full at ~250 call sites
/// buries the one thing that matters — which of the six roles this is.
extension DashboardStatusContext on BuildContext {
  AppStatusStyle status(AppStatusTone tone) => AppStatusStyle.of(this, tone);
}

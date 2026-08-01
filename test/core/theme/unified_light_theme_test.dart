import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// The light-mode half of [unified_dark_theme_test.dart].
///
/// Dark mode was unified first and is guarded there. This guards the promise
/// made on the other side: that the light theme is the same *system* at a
/// different brightness rather than a second design, and that the dashboard —
/// the app that had drifted furthest — cannot reintroduce a private palette.
///
/// The three failures being defended against, all of which were real:
///
/// 1. Three different light pages (`#FAFAF5` warm cream shared, `#F9FAFB` grey
///    client, `#F8FAFC` slate captain) for one product.
/// 2. A light [ColorScheme] that declared fourteen roles and let the rest fall
///    back, so secondary text collapsed to full black and every `*Container`
///    role came back as its saturated `error`/`primary` base.
/// 3. Status colours read as `static const` light values at ~250 dashboard call
///    sites, so a badge kept its pale `#CFFAFE` fill on a slate page.
void main() {
  double luminance(Color c) {
    double channel(double v) {
      final s = v / 255.0;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(c.r * 255) +
        0.7152 * channel(c.g * 255) +
        0.0722 * channel(c.b * 255);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// See the dark suite for why each pump needs a fresh [UniqueKey].
  Future<T> underTheme<T>(
    WidgetTester tester,
    ThemeData theme,
    T Function(BuildContext context) read,
  ) async {
    late T result;
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: theme,
        home: Builder(
          builder: (context) {
            result = read(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  group('the light scheme states every role it needs', () {
    test('secondary text is a real muted tone, not onSurface', () {
      final scheme = lightColorSchemeFromPalette();
      // The regression: an unset `onSurfaceVariant` resolves to `onSurface`, so
      // the ~320 call sites using it for captions rendered at full black and
      // the type hierarchy flattened.
      expect(scheme.onSurfaceVariant, isNot(scheme.onSurface));
      expect(scheme.onSurfaceVariant, AppLightColors.onSurfaceMuted);
    });

    test('container roles are containers, not their saturated base', () {
      final scheme = lightColorSchemeFromPalette();
      expect(scheme.errorContainer, isNot(scheme.error));
      expect(scheme.primaryContainer, isNot(scheme.primary));
      expect(scheme.secondaryContainer, isNot(scheme.secondary));
      expect(scheme.tertiaryContainer, isNot(scheme.tertiary));
    });

    test('the surface ladder has no flat rung', () {
      const tiers = [
        AppLightColors.canvas,
        AppLightColors.surfaceHighest,
        AppLightColors.surfaceRaised,
        AppLightColors.background,
        AppLightColors.surfaceLow,
        AppLightColors.surface,
      ];
      // Light mode runs the opposite direction to dark — it climbs *toward*
      // white — but the requirement is the same: every tier is distinguishable
      // from its neighbour, or a card loses its boundary against what it sits
      // on.
      for (var i = 1; i < tiers.length; i++) {
        expect(
          luminance(tiers[i]),
          greaterThan(luminance(tiers[i - 1])),
          reason: 'surface tier $i is not lighter than tier ${i - 1}',
        );
      }
    });

    test('light and dark are the same structure at two brightnesses', () {
      final light = lightColorSchemeFromPalette();
      final dark = darkColorSchemeFromPalette();
      // Brand identity is literally the same colour in both.
      expect(light.primary, dark.primary);
      expect(light.primary, AppLightColors.primary);
      // And M3's automatic hue tint is off on both, so an elevated card is the
      // tone the palette names rather than a violet-shifted version of it.
      expect(light.surfaceTint, Colors.transparent);
      expect(dark.surfaceTint, Colors.transparent);
    });
  });

  // These use `testWidgets` rather than `test` because building a ThemeData
  // builds its TextTheme, and google_fonts reaches for the network unless it is
  // running under `TestWidgetsFlutterBinding`.
  group('component coverage matches the dark theme', () {
    // The specific failure: light declared ten component themes to dark's
    // thirty, so a Switch was Material violet and a SnackBar Material charcoal
    // — neither from this palette. Asserting on the components rather than on
    // a count, so adding one to dark does not fail this for the wrong reason.
    testWidgets('controls and containers are themed, not left to Material', (
      tester,
    ) async {
      final light = AppTheme.lightTheme();
      expect(light.switchTheme.trackColor, isNotNull);
      expect(light.checkboxTheme.fillColor, isNotNull);
      expect(light.radioTheme.fillColor, isNotNull);
      expect(light.sliderTheme.activeTrackColor, AppLightColors.primary);
      expect(light.chipTheme.backgroundColor, isNotNull);
      expect(light.tabBarTheme.labelColor, AppLightColors.primaryAccent);
      expect(light.snackBarTheme.backgroundColor, isNotNull);
      expect(light.tooltipTheme.decoration, isNotNull);
      expect(light.navigationRailTheme.backgroundColor, isNotNull);
      expect(light.popupMenuTheme.color, isNotNull);
      expect(light.progressIndicatorTheme.color, AppLightColors.primary);
      expect(light.floatingActionButtonTheme.backgroundColor, isNotNull);
    });

    testWidgets('the dashboard page is the shared light page', (tester) async {
      expect(
        DashboardAppTheme.light().scaffoldBackgroundColor,
        AppLightColors.background,
      );
      expect(
        DashboardAppTheme.dark().scaffoldBackgroundColor,
        AppDarkColors.background,
      );
    });
  });

  group('contrast floors hold on the light palette', () {
    test('body and muted text clear AA on both page and card', () {
      for (final bg in [AppLightColors.background, AppLightColors.surface]) {
        expect(
          contrast(AppLightColors.onSurface, bg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppLightColors.onSurfaceMuted, bg),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('brand ink clears AA as text on the page', () {
      // The mirror of the dark assertion: here the ink tone is the *darker* of
      // the pair, because on white the brand has to descend to stay readable.
      expect(
        contrast(AppLightColors.primaryAccent, AppLightColors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        luminance(AppLightColors.primaryAccent),
        lessThan(luminance(AppLightColors.primary)),
      );
    });

    test('white clears AA on every tone used as a filled button', () {
      for (final fill in [
        AppLightColors.primary,
        AppLightColors.danger,
        AppLightColors.success,
        AppLightColors.warning,
      ]) {
        expect(
          contrast(AppLightColors.onFilled, fill),
          greaterThanOrEqualTo(4.5),
          reason: '$fill cannot carry white text',
        );
      }
    });

    test('status ink clears AA on its own container', () {
      const pairs = <(Color, Color)>[
        (AppLightColors.onSuccessContainer, AppLightColors.successContainer),
        (AppLightColors.onWarningContainer, AppLightColors.warningContainer),
        (AppLightColors.onDangerContainer, AppLightColors.dangerContainer),
        (AppLightColors.onPrimaryContainer, AppLightColors.primaryContainer),
        (AppLightColors.onNeutralContainer, AppLightColors.neutralContainer),
        (AppLightColors.onSpecialContainer, AppLightColors.specialContainer),
      ];
      for (final (ink, container) in pairs) {
        expect(
          contrast(ink, container),
          greaterThanOrEqualTo(4.5),
          reason: '$ink on $container',
        );
      }
    });

    test(
      'disabled ink is deliberately below the floor, and nothing else is',
      () {
        // Documented as sub-AA on purpose. Asserting it stays that way stops
        // someone "fixing" it into a second muted tone.
        expect(
          contrast(AppLightColors.onSurfaceFaint, AppLightColors.surface),
          lessThan(4.5),
        );
      },
    );
  });

  group('semantic status roles mean the same thing everywhere', () {
    test('success is the brand-family cyan, not green', () {
      // The dashboard shipped green (`#DCFCE7` / `#166534`) while both mobile
      // apps had already moved the positive role to cyan, so the same
      // "approved" badge was two different colours in two products.
      expect(AppStatusColors.successContainer, AppLightColors.successContainer);
      expect(
        AppStatusColors.onSuccessContainer,
        AppLightColors.onSuccessContainer,
      );
      // Cyan is blue-dominant; the old green was not.
      final success = AppLightColors.successInk;
      expect(success.b, greaterThan(success.g));
    });

    testWidgets('a status chip resolves differently in each theme', (
      tester,
    ) async {
      for (final tone in AppStatusTone.values) {
        final light = await underTheme(
          tester,
          AppTheme.lightTheme(),
          (context) => DashboardColors.status(context, tone),
        );
        final dark = await underTheme(
          tester,
          AppTheme.darkTheme(),
          (context) => DashboardColors.status(context, tone),
        );

        expect(
          light.tint,
          isNot(dark.tint),
          reason: '$tone renders the same fill in both themes',
        );
        // The actual bug: a near-white tint surviving onto a slate page.
        expect(luminance(light.tint), greaterThan(0.5), reason: '$tone light');
        expect(luminance(dark.tint), lessThan(0.2), reason: '$tone dark');
        // And each stays readable against its own fill.
        expect(
          contrast(light.ink, light.tint),
          greaterThanOrEqualTo(4.5),
          reason: '$tone light ink',
        );
        expect(
          contrast(dark.ink, dark.tint),
          greaterThanOrEqualTo(4.5),
          reason: '$tone dark ink',
        );
      }
    });
  });

  group('charts follow the theme', () {
    test('the chart palette is not one fixed set of colours', () {
      final light = DashboardChartPalette.resolve(Brightness.light);
      final dark = DashboardChartPalette.resolve(Brightness.dark);
      expect(light.positive, isNot(dark.positive));
      expect(light.negative, isNot(dark.negative));
    });

    test('every series reads against the surface it is painted on', () {
      // Chart fills sit on the page, not inside a container, so the floor is
      // the 3:1 non-text one. The dark series used to be the light `on*Container`
      // inks — near-black smudges on a slate card.
      final cases = <(DashboardChartPalette, Color)>[
        (
          DashboardChartPalette.resolve(Brightness.light),
          AppLightColors.surface,
        ),
        (DashboardChartPalette.resolve(Brightness.dark), AppDarkColors.surface),
      ];
      for (final (palette, surface) in cases) {
        for (final series in palette.categorical) {
          expect(
            contrast(series, surface),
            greaterThanOrEqualTo(3.0),
            reason: '$series is invisible on $surface',
          );
        }
      }
    });

    test('categorical series are distinct from one another', () {
      for (final brightness in Brightness.values) {
        final series = DashboardChartPalette.resolve(brightness).categorical;
        expect(
          series.toSet().length,
          series.length,
          reason: '$brightness repeats a category colour',
        );
      }
    });
  });
}

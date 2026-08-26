import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_palette.dart';
import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/core/theme/app_dark_colors.dart';

/// Guards the one thing the dark-theme unification actually promises: that a
/// screen in either app cannot pick up a colour the shared palette did not
/// hand it.
///
/// These are cheap identity and contrast assertions rather than golden images,
/// because the failure mode being defended against is not "this widget moved a
/// pixel" — it is someone reintroducing a second dark palette. Both apps used
/// to carry one: the client on Tailwind grey (`#111827`), the captain on slate
/// (`#1E293B`), meeting on every client screen because the scaffold came from
/// the shared theme and the cards came from the client's own tokens.
void main() {
  /// WCAG relative luminance.
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

  /// Builds a widget under [theme] and reads a value out of its context.
  ///
  /// Each pump gets a fresh [UniqueKey]. Without it a second `pumpWidget` in
  /// the same test reuses the existing element — the tree is structurally
  /// identical — and the builder never re-runs, so a light-mode read silently
  /// returns whatever the previous dark-mode pump produced.
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

  group('both apps resolve one dark palette', () {
    testWidgets('page, card and border agree across the two apps', (
      tester,
    ) async {
      final client = await underTheme(
        tester,
        ClientTheme.dark(),
        (context) => (
          background: ClientColors.backgroundFor(context),
          surface: ClientColors.surfaceFor(context),
          border: ClientColors.borderFor(context),
          text: ClientColors.textPrimaryFor(context),
          muted: ClientColors.textSecondaryFor(context),
        ),
      );

      final captain = await underTheme(
        tester,
        CaptainTheme.dark(),
        (context) => (
          background: CaptainColors.backgroundFor(context),
          surface: CaptainColors.surfaceFor(context),
          border: CaptainColors.dividerFor(context),
          text: CaptainColors.textPrimaryFor(context),
          muted: CaptainColors.textSecondaryFor(context),
        ),
      );

      expect(client.background, captain.background);
      expect(client.surface, captain.surface);
      expect(client.border, captain.border);
      expect(client.text, captain.text);
      expect(client.muted, captain.muted);

      // …and that shared value is the documented token, not a coincidence.
      //
      // The token is `ClientPalette.dark`, not `AppDarkColors`: the client
      // moved onto its own two-brightness palette with the EWT design import,
      // and the captain followed when `CaptainColors` became an alias onto
      // `ClientColors`. `AppDarkColors` is still the dashboard's palette, which
      // is why it survives further down this file.
      expect(client.background, ClientPalette.dark.bg);
      expect(client.surface, ClientPalette.dark.surface);
      expect(client.border, ClientPalette.dark.border);
    });

    testWidgets('the scaffold a screen gets matches the app tokens it draws '
        'its cards with', (tester) async {
      // This is the exact seam the old drift lived in: `Scaffold` takes its
      // colour from the shared ThemeData while a card takes its colour from
      // the app's own token class. If these two ever disagree again, a page
      // shows two different "backgrounds" at once.
      for (final theme in [ClientTheme.dark(), CaptainTheme.dark()]) {
        expect(theme.scaffoldBackgroundColor, ClientPalette.dark.bg);
        expect(theme.colorScheme.surface, ClientPalette.dark.surface);
      }
    });

    testWidgets('client surfaces climb the ladder instead of repeating it', (
      tester,
    ) async {
      final read = await underTheme(
        tester,
        ClientTheme.dark(),
        (context) => (
          tiers: [
            ClientColors.backgroundFor(context),
            ClientColors.surfaceSubtleFor(context),
            ClientColors.surfaceFor(context),
            ClientColors.surfaceMutedFor(context),
          ],
          surface: ClientColors.surfaceFor(context),
          raised: ClientColors.surfaceRaisedFor(context),
        ),
      );

      // Dark mode reads elevation as lightness, so each tier must actually be
      // lighter than the one below it — a ladder with a flat rung loses the
      // boundary between a card and what it sits on.
      final tiers = read.tiers;
      for (var i = 1; i < tiers.length; i++) {
        expect(
          luminance(tiers[i]),
          greaterThan(luminance(tiers[i - 1])),
          reason: 'surface tier $i is not lighter than tier ${i - 1}',
        );
      }

      // `surfaceRaised` is deliberately *not* a rung of its own. The EWT design
      // draws one card colour and lifts a card with a shadow rather than with a
      // lighter fill, so raised resolves to the same `--surface`. It is asserted
      // rather than dropped: if the two ever diverge, the ladder above has a
      // tier it is no longer checking.
      expect(read.raised, read.surface);
    });
  });

  group('contrast floors hold on the dark palette', () {
    test('body and muted text clear AA on both page and card', () {
      for (final bg in [AppDarkColors.background, AppDarkColors.surface]) {
        expect(
          contrast(AppDarkColors.onSurface, bg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppDarkColors.onSurfaceMuted, bg),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('brand ink clears AA as text where brand fill would not', () {
      // The reason the palette carries two brand tones at all.
      expect(
        contrast(AppDarkColors.primaryAccent, AppDarkColors.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppDarkColors.primary, AppDarkColors.background),
        lessThan(4.5),
      );
    });

    test('white clears AA on every tone used as a filled button', () {
      for (final fill in [
        AppDarkColors.primary,
        AppDarkColors.danger,
        ClientColors.journeyRed,
        ClientColors.journeyRedStrong,
      ]) {
        expect(
          contrast(AppDarkColors.onPrimary, fill),
          greaterThanOrEqualTo(4.5),
          reason: '$fill cannot carry white text',
        );
      }
    });

    test('status ink clears AA on its own container', () {
      const pairs = <(Color, Color)>[
        (AppDarkColors.onSuccessContainer, AppDarkColors.successContainer),
        (AppDarkColors.onWarningContainer, AppDarkColors.warningContainer),
        (AppDarkColors.onDangerContainer, AppDarkColors.dangerContainer),
        (AppDarkColors.onPrimaryContainer, AppDarkColors.primaryContainer),
        (AppDarkColors.onNeutralContainer, AppDarkColors.neutralContainer),
        (AppDarkColors.onSpecialContainer, AppDarkColors.specialContainer),
      ];
      for (final (ink, container) in pairs) {
        expect(
          contrast(ink, container),
          greaterThanOrEqualTo(4.5),
          reason: '$ink on $container',
        );
      }
    });
  });

  group('client status colours resolve for the active brightness', () {
    testWidgets('a status container is dark in dark mode, tinted in light', (
      tester,
    ) async {
      final dark = await underTheme(
        tester,
        ClientTheme.dark(),
        (context) => ClientColors.journeyCyanLightFor(context),
      );
      final light = await underTheme(
        tester,
        ClientTheme.light(),
        (context) => ClientColors.journeyCyanLightFor(context),
      );

      // The bug this replaces: a `#CFFAFE` chip rendered on a slate page. A
      // dark container is allowed to sit a little *above* the card it rests on
      // — that is what makes it visible as a tint — so the invariant is that it
      // stays in the dark end of the range, not that it is darker than the card.
      expect(luminance(dark), lessThan(0.1));
      expect(luminance(light), greaterThan(0.7));
      expect(
        contrast(dark, AppDarkColors.onSuccessContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('every journey badge stays legible in dark mode', (
      tester,
    ) async {
      final badges = await underTheme(
        tester,
        ClientTheme.dark(),
        (context) => [
          for (final status in ClientJourneyStatus.values)
            (status, ClientColors.journeyBadgeFor(context, status)),
        ],
      );

      for (final (status, badge) in badges) {
        expect(
          contrast(badge.fg, badge.bg),
          greaterThanOrEqualTo(4.5),
          reason: '$status label is unreadable on its own badge',
        );
      }
    });

    testWidgets('primary works as both ink and fill in dark', (tester) async {
      final tones = await underTheme(
        tester,
        ClientTheme.dark(),
        (context) => (
          ink: ClientColors.primaryFor(context),
          fill: ClientColors.primaryFillFor(context),
          onFill: ClientColors.onPrimaryFor(context),
        ),
      );

      // The client used to carry two brand tones in dark — a readable ink and a
      // separate fill — because the fill was a deep blue that could not be read
      // as text. The EWT palette instead makes dark `--primary` a bright cyan
      // and flips `--on-primary` to near-black, so one tone does both jobs.
      expect(tones.ink, tones.fill);

      // Ink has to read on the page…
      expect(
        contrast(tones.ink, ClientPalette.dark.bg),
        greaterThanOrEqualTo(4.5),
      );
      // …and the fill has to carry its own on-colour. Note that is *not* white:
      // white on this cyan is 2.4:1, which is exactly why the palette declares
      // `onPrimary` per brightness instead of assuming it.
      expect(
        contrast(tones.onFill, tones.fill),
        greaterThanOrEqualTo(4.5),
        reason: 'onPrimary is unreadable on the primary fill',
      );
    });
  });
}

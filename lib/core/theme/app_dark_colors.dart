import 'package:flutter/material.dart';

/// The one dark palette both the captain and the client app are drawn in.
///
/// It is lifted from the captain's profile screen, which is the reference for
/// what dark mode should look like here: a slate canvas, one step lighter for
/// every surface that sits on it, brand blue reserved for what the user can act
/// on, and a muted slate for everything the eye should skip.
///
/// Before this existed each app carried its own dark values — the captain on
/// slate, the client on Tailwind grey, and the shared [ColorScheme] on a third
/// near-black/violet set that neither had designed. A single screen could show
/// all three at once: the profile page painted a slate background and then
/// stacked cards that read `Theme.of(context).colorScheme.surface` and came back
/// violet. Everything now resolves here, so a screen cannot drift.
///
/// ## The surface ladder
///
/// Dark mode conveys elevation with lightness, not shadow, so each tier up is
/// lighter than the one below it:
///
/// | Token             | Value     | What sits on it                       |
/// |-------------------|-----------|---------------------------------------|
/// | [canvas]          | `#0B1220` | Wells, map backdrops, inset tracks    |
/// | [background]      | `#0F172A` | The page itself (scaffold)            |
/// | [surfaceLow]      | `#172033` | Gradient tails, quiet bands           |
/// | [surface]         | `#1E293B` | Cards, sheets, dialogs, nav bars      |
/// | [surfaceRaised]   | `#26334A` | Tiles nested inside a card            |
/// | [surfaceHighest]  | `#334155` | Inputs, secondary buttons, skeletons  |
///
/// ## Why brand blue comes in two tones
///
/// [primary] is the fill tone: white on it clears WCAG AA (4.87:1), so every
/// filled button, FAB and gradient keeps the exact brand blue it has in light
/// mode. But that same blue *as ink* on [background] is only 3.66:1, which is
/// under the floor for text. [primaryAccent] is the ink tone — the same hue two
/// steps lighter, 7.0:1 on [background] — and is what links, active tabs and
/// tinted icons use. The pair reads as one colour and each half passes the
/// contrast test its role is actually held to. [danger]/[dangerInk] split for
/// the same reason.
abstract final class AppDarkColors {
  // ── Surfaces ───────────────────────────────────────────────────────────────

  /// Deeper than the page. For content that should read as cut *into* the
  /// surface — map backdrops, progress tracks, inset wells.
  static const Color canvas = Color(0xFF0B1220);

  /// The page. Everything else in this file is measured against it.
  static const Color background = Color(0xFF0F172A); // Slate 900

  /// A half-step above [background], for quiet bands and gradient tails that
  /// should separate from the page without becoming a card.
  static const Color surfaceLow = Color(0xFF172033);

  /// Cards, grouped lists, bottom sheets, dialogs, app bars, nav bars.
  static const Color surface = Color(0xFF1E293B); // Slate 800

  /// A tile nested inside a [surface] card, which cannot repeat its parent's
  /// colour without disappearing into it.
  static const Color surfaceRaised = Color(0xFF26334A);

  /// The top of the ladder: input fills, secondary buttons, skeleton bases,
  /// neutral chips.
  static const Color surfaceHighest = Color(0xFF334155); // Slate 700

  // ── Ink ────────────────────────────────────────────────────────────────────

  /// Titles, values, anything the user came to the screen to read.
  static const Color onSurface = Color(0xFFF8FAFC); // Slate 50

  /// Labels, captions, supporting detail. 5.97:1 on [surface] — muted, still
  /// comfortably readable.
  static const Color onSurfaceMuted = Color(0xFF94A3B8); // Slate 400

  /// Disabled text, placeholders, and the third line of a row. Below the AA
  /// floor by design: never use it for information the user must read.
  static const Color onSurfaceFaint = Color(0xFF64748B); // Slate 500

  // ── Lines ──────────────────────────────────────────────────────────────────

  /// Card borders and the hairline between rows in a grouped list.
  static const Color border = Color(0xFF334155); // Slate 700

  /// For a line inside an already-bordered surface, which would otherwise
  /// compete with the border around it.
  static const Color borderSubtle = Color(0xFF2A3648);

  /// A border that has to carry weight on its own — the outline of a selected
  /// tile, a divider between two same-coloured surfaces, the edge of an input
  /// that is doing the separating rather than the fill behind it.
  static const Color borderStrong = Color(0xFF475569); // Slate 600

  // ── Brand ──────────────────────────────────────────────────────────────────

  /// Brand blue, unchanged from light mode. The **fill** tone: white on it is
  /// 4.87:1. Buttons, FABs, selected states, gradients.
  static const Color primary = Color(0xFF2563EB); // Blue 600

  static const Color onPrimary = Color(0xFFFFFFFF);

  /// The **ink** tone of the same blue: 7.0:1 on [background]. Links, active
  /// nav items, tinted icons, focus rings, progress indicators — anywhere the
  /// brand appears as text or a thin mark rather than as a filled shape.
  static const Color primaryAccent = Color(0xFF60A5FA); // Blue 400

  /// A brand-tinted fill that is still a surface: selected rows, brand chips,
  /// the "current step" of a progression.
  static const Color primaryContainer = Color(0xFF1E3A8A); // Blue 900

  static const Color onPrimaryContainer = Color(0xFFDBEAFE); // Blue 100

  /// The deep end of the brand gradient. Pairs with [primary] for the profile
  /// hero, the splash mark and the auth lockup.
  static const Color primaryDeep = Color(0xFF4338CA); // Indigo 700

  /// The gradient the profile hero is built on, and the reason the dark theme
  /// looks the way it does. Deep enough that white text on it clears AA.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  // ── Status ─────────────────────────────────────────────────────────────────
  //
  // Neither app uses green: "confirmed / on-time / done" is a cyan that sits in
  // the brand's own family, so a positive state reads as part of the product
  // rather than as a foreign accent. Amber and red survive because a warning
  // that shares the brand hue stops registering as a warning.

  /// Confirmed, on-time, completed, online. The fill tone.
  static const Color success = Color(0xFF0EA5E9); // Sky 500

  /// Success as ink on a dark surface.
  static const Color successInk = Color(0xFF22D3EE); // Cyan 400
  static const Color successContainer = Color(0xFF0C3946);
  static const Color onSuccessContainer = Color(0xFFA5F3FC);

  /// Departing soon, scarcity, action needed.
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningInk = Color(0xFFFBBF24); // Amber 400
  static const Color warningContainer = Color(0xFF3A2A0A);
  static const Color onWarningContainer = Color(0xFFFDE68A);

  /// Cancelled, failed, destructive. The fill tone — white on it is 4.83:1.
  static const Color danger = Color(0xFFDC2626); // Red 600
  static const Color onDanger = Color(0xFFFFFFFF);

  /// Danger as ink: error messages, failed-state labels and icons.
  static const Color dangerInk = Color(0xFFF87171); // Red 400
  static const Color dangerContainer = Color(0xFF3A1518);
  static const Color onDangerContainer = Color(0xFFFECACA);

  /// Informational, and the "upcoming" state of a journey.
  static const Color info = primaryAccent;
  static const Color infoContainer = primaryContainer;
  static const Color onInfoContainer = onPrimaryContainer;

  /// Inactive, historical, dimmed — a state with no urgency attached.
  static const Color neutral = onSurfaceMuted;
  static const Color neutralContainer = Color(0xFF24314A);
  static const Color onNeutralContainer = Color(0xFFCBD5E1); // Slate 300

  /// Packages, subscriptions, premium. The one hue outside the blue family, and
  /// it is spent deliberately.
  static const Color special = Color(0xFFA78BFA); // Violet 400
  static const Color specialContainer = Color(0xFF2E1F4D);
  static const Color onSpecialContainer = Color(0xFFDDD6FE);

  /// Star ratings. Kept apart from [warning] on purpose: a rating is not a
  /// caution, and the two have to stay independently tunable.
  static const Color rating = Color(0xFFFBBF24); // Amber 400

  // ── Depth ──────────────────────────────────────────────────────────────────

  /// Dark mode reads elevation from lightness, so shadows here are for
  /// separation only — near-black and soft, never the heavy drop shadow that
  /// works on white.
  static const Color shadow = Color(0xFF000000);

  static const Color scrim = Color(0xCC060B15);

  /// A card lifted off the page.
  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// A floating element — the bottom nav, a FAB, a sticky action bar.
  static List<BoxShadow> get floatingShadow => const [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: 1,
    ),
  ];
}

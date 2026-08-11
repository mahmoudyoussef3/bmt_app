import 'package:flutter/material.dart';

/// The one light palette all three EWT apps are drawn in — the twin of
/// [AppDarkColors](app_dark_colors.dart).
///
/// Dark mode was unified first, onto **slate**. This file finishes the job for
/// the other half. Before it existed, the light values were the last place the
/// three apps still disagreed, and they disagreed on the page itself:
///
/// | App       | Page      | Body text | Border    |
/// |-----------|-----------|-----------|-----------|
/// | shared    | `#FAFAF5` | `#1F2937` | `#E5E7EB` |
/// | client    | `#F9FAFB` | `#111827` | `#E5E7EB` |
/// | captain   | `#F8FAFC` | `#0F172A` | `#E2E8F0` |
///
/// A warm cream, a neutral grey and a cool slate — three different pages for
/// one product, and the shared one was the odd hue out. Everything now resolves
/// to the slate column, which is the family dark mode already uses, so the two
/// themes are the same design seen under different light rather than two
/// designs.
///
/// ## The surface ladder
///
/// Dark mode conveys elevation by getting *lighter*; light mode has nowhere
/// above white to go, so it conveys elevation by getting *darker* — a tile
/// nested in a white card has to be tinted down to be seen at all. The roles
/// below are therefore the same six as [AppDarkColors], in the same order of
/// meaning, but not in the same order of lightness. This is why the light theme
/// is not the dark theme inverted.
///
/// | Token             | Value     | What sits on it                       |
/// |-------------------|-----------|---------------------------------------|
/// | [canvas]          | `#E6EBF2` | Wells, map backdrops, inset tracks    |
/// | [background]      | `#F4F7FB` | The page itself (scaffold)            |
/// | [surfaceLow]      | `#FAFBFD` | Gradient tails, quiet bands           |
/// | [surface]         | `#FFFFFF` | Cards, sheets, dialogs, nav bars      |
/// | [surfaceRaised]   | `#F1F4F9` | Tiles nested inside a card            |
/// | [surfaceHighest]  | `#EDF1F7` | Inputs, table headers, skeletons      |
///
/// Read as a lightness ramp the order is
/// `canvas < surfaceHighest < surfaceRaised < background < surfaceLow <
/// surface` — the same sequence Material 3 uses for its light containers, where
/// `surfaceContainerHigh` sits *below* `surfaceContainerLowest`.
///
/// ## Why brand blue comes in two tones
///
/// The same split [AppDarkColors] makes, mirrored. [primary] is the fill tone —
/// white on it is 4.87:1, so every filled button keeps the exact brand blue it
/// has in dark mode. [primaryAccent] is the ink tone, and here it is the
/// *darker* of the two (`#1D4ED8`, 6.9:1 on white) rather than the lighter one,
/// because on a white page the brand has to descend to stay readable where on a
/// slate page it has to rise. Same relationship, opposite direction.
///
/// ## No green
///
/// "Confirmed / on-time / completed" is cyan, not green — the client app's
/// journey palette, which keeps a positive state inside the brand's own family
/// instead of importing a foreign accent. Amber and red survive because a
/// warning that shares the brand hue stops registering as a warning.
abstract final class AppLightColors {
  
  /// Deeper than the page. For content that should read as cut *into* the
  /// surface — map backdrops, progress tracks, inset wells.
  static const Color canvas = Color(0xFFE6EBF2);

  /// The page. Everything else in this file is measured against it.
  static const Color background = Color(0xFFF4F7FB);

  /// A half-step from the page toward a card, for quiet bands and gradient
  /// tails that should separate from the page without becoming a card.
  static const Color surfaceLow = Color(0xFFFAFBFD);

  /// Cards, grouped lists, bottom sheets, dialogs, app bars, nav bars.
  static const Color surface = Color(0xFFFFFFFF);

  /// A tile nested inside a [surface] card, which cannot repeat its parent's
  /// colour without disappearing into it. Tinted a step *below* [background]:
  /// a nested tile has to read as deeper than the card around it, and a card is
  /// already lighter than the page.
  static const Color surfaceRaised = Color(0xFFF1F4F9);

  /// The top of the ladder: input fills, table headers, secondary buttons,
  /// skeleton bases, neutral chips.
  static const Color surfaceHighest = Color(0xFFEDF1F7);

  /// Titles, values, anything the user came to the screen to read.
  /// 17.4:1 on [surface].
  static const Color onSurface = Color(0xFF0F172A); 

  /// Labels, captions, supporting detail. 7.6:1 on [surface] and 7.1:1 on
  /// [background].
  ///
  /// Slate 600 rather than the Slate 500 (`#64748B`) the captain app carried:
  /// 500 is 4.76:1 on a white card but only **4.43:1** on the page, so the same
  /// caption passed AA inside a card and failed it directly on the scaffold —
  /// a floor that depends on which parent a widget happens to have is not a
  /// floor. One step down clears both with room to spare.
  static const Color onSurfaceMuted = Color(0xFF475569); 

  /// Disabled text, placeholders, and the third line of a row. Below the AA
  /// floor by design: never use it for information the user must read.
  static const Color onSurfaceFaint = Color(0xFF94A3B8); 

  /// Ink on a filled brand/danger surface.
  static const Color onFilled = Color(0xFFFFFFFF);

  /// Card borders and the hairline between rows in a grouped list.
  static const Color border = Color(0xFFE2E8F0); 

  /// For a line inside an already-bordered surface, which would otherwise
  /// compete with the border around it.
  static const Color borderSubtle = Color(0xFFEDF1F6);

  /// A border that has to carry weight on its own — the outline of a selected
  /// tile, a divider between two same-coloured surfaces, the edge of an input
  /// that is doing the separating rather than the fill behind it.
  static const Color borderStrong = Color(0xFFCBD5E1); 

  /// Brand blue, identical to [AppDarkColors.primary]. The **fill** tone:
  /// white on it is 4.87:1. Buttons, FABs, selected states, gradients.
  static const Color primary = Color(0xFF2563EB); 

  static const Color onPrimary = Color(0xFFFFFFFF);

  /// The **ink** tone of the same blue: 6.9:1 on [surface]. Links, active nav
  /// items, tinted icons, focus rings — anywhere the brand appears as text or
  /// a thin mark rather than as a filled shape.
  static const Color primaryAccent = Color(0xFF1D4ED8); 

  /// A brand-tinted fill that is still a surface: selected rows, brand chips,
  /// the "current step" of a progression.
  static const Color primaryContainer = Color(0xFFDBEAFE); 

  static const Color onPrimaryContainer = Color(0xFF1E3A8A); 

  /// The deep end of the brand gradient. Pairs with [primary] for the hero
  /// lockups, the splash mark and the auth screen.
  static const Color primaryDeep = Color(0xFF4338CA); 

  /// The gradient the hero lockups are built on — the same two stops as
  /// [AppDarkColors.brandGradient], so the brand sweep is one object across
  /// both themes.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  /// Confirmed, on-time, completed, online. The fill tone — white on it is
  /// 5.3:1.
  static const Color success = Color(0xFF0E7490); 

  /// Success as ink on a light surface. 4.5:1 on [surface].
  static const Color successInk = Color(0xFF0891B2); 
  static const Color successContainer = Color(0xFFCFFAFE); 
  static const Color onSuccessContainer = Color(0xFF164E63); 

  /// Departing soon, scarcity, action needed.
  static const Color warning = Color(0xFFB45309); 
  static const Color warningInk = Color(0xFFD97706); 
  static const Color warningContainer = Color(0xFFFEF3C7); 
  static const Color onWarningContainer = Color(0xFF78350F); 

  /// Cancelled, failed, destructive. The fill tone — white on it is 4.83:1.
  static const Color danger = Color(0xFFDC2626); 
  static const Color onDanger = Color(0xFFFFFFFF);

  /// Danger as ink: error messages, failed-state labels and icons.
  static const Color dangerInk = Color(0xFFDC2626); 
  static const Color dangerContainer = Color(0xFFFEE2E2); 
  static const Color onDangerContainer = Color(0xFF7F1D1D); 

  /// Informational, and the "upcoming" state of a journey.
  static const Color info = primaryAccent;
  static const Color infoContainer = primaryContainer;
  static const Color onInfoContainer = Color(0xFF1E40AF); 

  /// Inactive, historical, dimmed — a state with no urgency attached.
  static const Color neutral = onSurfaceMuted;
  static const Color neutralContainer = Color(0xFFF1F5F9); 
  static const Color onNeutralContainer = Color(0xFF1E293B); 

  /// Packages, subscriptions, premium. The one hue outside the blue family,
  /// and it is spent deliberately.
  static const Color special = Color(0xFF7C3AED); 
  static const Color specialContainer = Color(0xFFF5F3FF); 
  static const Color onSpecialContainer = Color(0xFF3B0764); 

  /// Star ratings. Kept apart from [warning] on purpose: a rating is not a
  /// caution, and the two have to stay independently tunable.
  static const Color rating = Color(0xFFD97706); 

  /// Light mode reads elevation from shadow rather than lightness, so unlike
  /// the dark palette these carry real weight. The tint is slate rather than
  /// pure black — a neutral-black shadow over a slate page reads muddy.
  static const Color shadow = Color(0xFF1E293B);

  static const Color scrim = Color(0x661E293B);

  /// A card lifted off the page.
  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x141E293B), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// A floating element — a menu, a FAB, a sticky action bar.
  static List<BoxShadow> get floatingShadow => const [
    BoxShadow(
      color: Color(0x1F1E293B),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: 1,
    ),
  ];
}

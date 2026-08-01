import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

/// The history tab's colours — one blue family, and no green.
///
/// Green used to mark a completed trip here, which spent the app's loudest
/// semantic colour on the one fact every row on this screen already shares:
/// they are all complete, or they would not be in the history. That left the
/// tab reading as a wall of green badges that said nothing and pulled against
/// the brand blue everywhere else in the app.
///
/// So colour is spent only where it still separates one trip from another: the
/// brand family carries the trip's identity, and [attention] marks the single
/// fact a captain might still want to look twice at — a boarding shortfall.
class TripHistoryPalette {
  const TripHistoryPalette._();

  /// The trip's identity: route marks, headline figures, timeline stations.
  static const Color accent = CaptainColors.primary; // Blue 600

  /// The deep end of the brand gradient. Pairs with [accent] so neighbouring
  /// figures stay distinguishable without leaving the family.
  static const Color accentDeep = CaptainColors.primaryDeep; // Indigo 700

  /// The one colour from outside the family. Not every trip boards everyone it
  /// sold, and unlike "completed" that is not true of every row here.
  static const Color attention = CaptainColors.warning; // Amber 500

  /// Facts that carry no state of their own — vehicle, duration, stop times.
  static Color neutral(BuildContext context) =>
      CaptainColors.textSecondaryFor(context);

  /// A wash of [accent] behind card headers and icon plates.
  ///
  /// Dark surfaces swallow a 6% tint of anything, so the wash is carried at a
  /// weight that stays visible against them rather than at one fixed alpha.
  static Color wash(BuildContext context) {
    return accent.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.05,
    );
  }

  /// The colour a boarding figure earns: a full bus is unremarkable and stays
  /// in the family, anything short of it goes amber.
  static Color boarding(double rate) => rate >= 1 ? accent : attention;

  /// The brand gradient, for the marks that stand in for a trip.
  static const LinearGradient markGradient = LinearGradient(
    colors: [accent, accentDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  /// The same mark for a trip that did not board everyone it sold.
  static const LinearGradient shortfallGradient = LinearGradient(
    colors: [attention, Color(0xFFB45309)], // Amber 500 → Amber 700
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  /// The mark a trip earns.
  ///
  /// The mark used to be the same gradient on every row — a decoration that
  /// took the card's most prominent spot to say nothing, since every trip in
  /// the history has one. Tying it to the boarding outcome spends that spot on
  /// the one thing that separates these rows, so a captain scrolling the tab
  /// sees which trips came up short before reading any of them.
  ///
  /// A trip that sold nothing is not a shortfall — there was nobody to board —
  /// so it keeps the brand mark.
  static LinearGradient mark({required int boarded, required int total}) {
    if (total == 0 || boarded >= total) return markGradient;
    return shortfallGradient;
  }
}

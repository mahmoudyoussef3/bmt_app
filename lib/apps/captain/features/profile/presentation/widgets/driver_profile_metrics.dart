import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

/// Geometry shared between the loaded profile hero and its loading skeleton.
///
/// The two must agree or the load→loaded transition visibly jumps, which is
/// exactly what happened while each file carried its own copy of the numbers.
class DriverProfileMetrics {
  DriverProfileMetrics._();

  /// Diameter of the hero avatar.
  ///
  /// The identity used to ride a 38px circle on a single toolbar row beside the
  /// captain's name — the user chip a web console tucks in its top corner. A
  /// phone's profile screen leads with the person, so the avatar is now the
  /// largest thing on the hero and the name sits under it.
  static const double avatarSize = 88;

  /// Inset of the hero's content from the screen edges.
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(
    CaptainDesignTokens.s24,
    CaptainDesignTokens.s8,
    CaptainDesignTokens.s24,
    CaptainDesignTokens.s24,
  );

  /// The hero's rounded bottom edge, so it reads as a card the rest of the
  /// screen scrolls out from under rather than as a painted band.
  static const BorderRadius heroRadius = BorderRadius.only(
    bottomLeft: CaptainDesignTokens.r32,
    bottomRight: CaptainDesignTokens.r32,
  );

  /// Height of the two lifetime-total tiles carried at the foot of the hero.
  static const double statTileHeight = 74;
}

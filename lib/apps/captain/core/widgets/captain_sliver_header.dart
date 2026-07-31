import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_typography.dart';

/// Title over an optional one-line subtitle, styled identically for both
/// [CaptainSliverHeader] and [CaptainAppBar] — the single place that decides
/// what a captain sub-screen's title looks like.
Widget _captainHeaderTitle(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CaptainTypography.titleMedium(context).copyWith(
          fontWeight: FontWeight.w800,
          color: CaptainColors.textPrimaryFor(context),
        ),
      ),
      if (subtitle != null)
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.labelMedium(
            context,
          ).copyWith(color: CaptainColors.textSecondaryFor(context)),
        ),
    ],
  );
}

/// The shared header for captain sub-screens — trip history, trip execution,
/// and the passenger manifest each hand-rolled this exact `SliverAppBar` shape
/// with slightly different heights, paddings, and background-color sources
/// before this existed. This is the one copy; give it a title and an optional
/// one-line subtitle.
///
/// It is a plain pinned toolbar, not a collapsing hero: the title and subtitle
/// are two short lines, and an expanded height tall enough to animate them into
/// place spent most of the screen's top on empty background.
///
/// Not for every header in the app — the Home dashboard's greeting and the
/// Profile screen's identity bar are intentionally distinct, carrying the
/// captain rather than a screen name.
class CaptainSliverHeader extends StatelessWidget {
  const CaptainSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;

  /// Trailing controls (e.g. "mark all as read"). Rare — most sub-screens
  /// carry none.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    // Title over subtitle measures ~38 at scale 1.0, so the standard toolbar
    // already fits both with room to breathe — the bar only has to grow once
    // the user's text scale pushes the column past it.
    final toolbarHeight = math.max(
      kToolbarHeight,
      MediaQuery.textScalerOf(context).scale(subtitle == null ? 40 : 50),
    );

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      backgroundColor: CaptainColors.surfaceFor(context),
      iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
      title: _captainHeaderTitle(context, title: title, subtitle: subtitle),
      actions: actions,
    );
  }
}

/// The fixed (non-sliver) counterpart to [CaptainSliverHeader], for the one
/// shape of screen a sliver header doesn't fit: a message thread, where the
/// scrollable list sits between a fixed title bar and a fixed composer.
/// Forcing that layout into a `CustomScrollView` buys nothing — the composer
/// still has to live outside the scroll view — so this exists to give
/// `Scaffold.appBar` screens the same title/subtitle typography and colors as
/// every sliver-headed sub-screen, rather than falling back to a bare
/// `AppBar` that only inherits the ambient theme.
///
/// Prefer [CaptainSliverHeader] whenever the body is already (or can easily
/// be) a `CustomScrollView` — it also grows with the user's text scale, which
/// this fixed-height `PreferredSizeWidget` cannot.
class CaptainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CaptainAppBar({super.key, required this.title, this.subtitle, this.actions});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      toolbarHeight: preferredSize.height,
      backgroundColor: CaptainColors.surfaceFor(context),
      iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
      title: _captainHeaderTitle(context, title: title, subtitle: subtitle),
      actions: actions,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : kToolbarHeight + 14);
}

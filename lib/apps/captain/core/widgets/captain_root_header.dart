import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import 'captain_notification_bell.dart';

/// The header on the three tab roots.
///
/// The design drops the brand-blue gradient band that used to crown every tab.
/// A full-width coloured bar is the loudest thing on a screen, and it was
/// spending that on "which tab am I on" — a question the nav bar at the bottom
/// already answers. The header now sits on the page in ordinary text, and the
/// only brand colour left above the fold is the trip card itself, which is what
/// the captain actually came to look at.
class CaptainRootHeader extends StatelessWidget {
  const CaptainRootHeader({
    super.key,
    required this.title,
    required this.onNotificationsTap,
    this.onAvatarTap,
  });

  final Widget title;

  final VoidCallback onNotificationsTap;

  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final toolbarHeight = math.max(
      kToolbarHeight,
      MediaQuery.textScalerOf(context).scale(64),
    );

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: toolbarHeight,
      backgroundColor: CaptainColors.backgroundFor(context),
      surfaceTintColor: Colors.transparent,
      foregroundColor: CaptainColors.textPrimaryFor(context),
      titleSpacing: CaptainDesignTokens.s20,
      title: title,
      actions: [
        CaptainNotificationBell(onTap: onNotificationsTap),
        const SizedBox(width: CaptainDesignTokens.s20),
      ],
    );
  }

  /// A tab root's title: the screen's name, with one quiet line of context
  /// under it.
  static Widget titleSubtitle(
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
          style: CaptainTypography.titleLarge(context).copyWith(
            color: CaptainColors.textPrimaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.bodySmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

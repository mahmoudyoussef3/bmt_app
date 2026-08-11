import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/widgets.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';
import 'captain_notification_bell.dart';

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
      toolbarHeight: toolbarHeight,
      backgroundColor: CaptainColors.primary,
      foregroundColor: Colors.white,
      titleSpacing: CaptainDesignTokens.s20,
      title: title,
      actions: [
        CaptainNotificationBell(onTap: onNotificationsTap),

        const SizedBox(width: CaptainDesignTokens.s20),
      ],
      flexibleSpace: const _HeaderBackground(),
    );
  }

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
          style: CaptainTypography.titleMedium(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.labelMedium(context).copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CaptainColors.primaryGradient(context),
      ),
    );
  }
}

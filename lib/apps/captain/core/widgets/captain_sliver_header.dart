import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_typography.dart';

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

class CaptainSliverHeader extends StatelessWidget {
  const CaptainSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
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

class CaptainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CaptainAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

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

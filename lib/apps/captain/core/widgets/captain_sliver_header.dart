import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes/captain_nav.dart';
import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
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
        style: CaptainTypography.titleSmall(context).copyWith(
          fontWeight: FontWeight.w800,
          color: CaptainColors.textPrimaryFor(context),
        ),
      ),
      if (subtitle != null)
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.labelMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  );
}

/// The design's back affordance: a 36×36 `--surface2` square, not a bare glyph.
///
/// `Icons.arrow_back_ios_new` carries `matchTextDirection`, so Flutter mirrors
/// it for RTL on its own — reaching for a forward arrow here would flip it
/// twice and point the captain out of the app.
class CaptainBackButton extends StatelessWidget {
  const CaptainBackButton({super.key, this.onPressed});

  static const double size = 36;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: InkWell(
        onTap: onPressed ?? () => context.closeScreen(),
        borderRadius: CaptainDesignTokens.br12,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CaptainColors.surfaceAltFor(context),
            borderRadius: CaptainDesignTokens.br12,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: CaptainColors.textPrimaryFor(context),
          ),
        ),
      ),
    );
  }
}

Widget? _leadingFor(BuildContext context) {
  // A tab root has nothing to go back to; only a pushed screen gets the square.
  if (!Navigator.of(context).canPop()) return null;
  return const Center(child: CaptainBackButton());
}

PreferredSizeWidget _hairline(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(height: 1, color: CaptainColors.borderFor(context)),
  );
}

/// A pushed screen's header: back square, bold title, and a hairline that
/// separates it from the content scrolling under it.
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
      scrolledUnderElevation: 0,
      toolbarHeight: toolbarHeight,
      backgroundColor: CaptainColors.backgroundFor(context),
      surfaceTintColor: Colors.transparent,
      leadingWidth: CaptainBackButton.size + CaptainDesignTokens.s24,
      leading: _leadingFor(context),
      titleSpacing: CaptainDesignTokens.s4,
      iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
      title: _captainHeaderTitle(context, title: title, subtitle: subtitle),
      actions: actions,
      bottom: _hairline(context),
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
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height - 1,
      backgroundColor: CaptainColors.backgroundFor(context),
      surfaceTintColor: Colors.transparent,
      leadingWidth: CaptainBackButton.size + CaptainDesignTokens.s24,
      leading: _leadingFor(context),
      titleSpacing: CaptainDesignTokens.s4,
      iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
      title: _captainHeaderTitle(context, title: title, subtitle: subtitle),
      actions: actions,
      bottom: _hairline(context),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (subtitle == null ? kToolbarHeight : kToolbarHeight + 14) + 1,
  );
}

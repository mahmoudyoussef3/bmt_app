import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_app_bar.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The scrolling counterpart to [ClientAppBar], for screens whose header is
/// part of a [CustomScrollView].
///
/// It carries the same title typography, back affordance and flat surface, so a
/// collapsing header and a fixed one are visibly the same component. Pass
/// [background] (plus [expandedHeight]) for headers that reveal artwork — a
/// photo gallery, a route map — and leave both null for a plain pinned bar.
class ClientSliverAppBar extends StatelessWidget {
  const ClientSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.expandedHeight,
    this.background,
    this.stretch = false,
    this.stretchModes = const [StretchMode.zoomBackground],
    this.pinned = true,
    this.floating = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  /// Height of the header when fully expanded. Required for [background] to be
  /// visible; without it the bar stays at toolbar height.
  final double? expandedHeight;

  /// Artwork revealed behind the title as the header expands.
  final Widget? background;

  /// Lets [background] overscroll past [expandedHeight] — a photo gallery reads
  /// as elastic, a map does not.
  final bool stretch;

  final List<StretchMode> stretchModes;

  final bool pinned;
  final bool floating;
  final Color? backgroundColor;
  final Color? foregroundColor;

  bool _canPop(BuildContext context) =>
      onBack != null ||
      (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

  @override
  Widget build(BuildContext context) {
    final surface = backgroundColor ?? ClientColors.surfaceFor(context);
    final foreground = foregroundColor ?? ClientColors.textPrimaryFor(context);
    final isDark =
        ThemeData.estimateBrightnessForColor(surface) == Brightness.dark;

    final titleBlock = ClientAppBarTitle(
      title: title,
      subtitle: subtitle,
      color: foreground,
    );

    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      stretch: stretch,
      expandedHeight: expandedHeight,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      leading: _canPop(context)
          ? IconButton(
              icon: const DirectionalIcon(Icons.arrow_back_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
      
      title: titleBlock,
      flexibleSpace: background == null
          ? null
          : FlexibleSpaceBar(
              stretchModes: stretchModes,
              background: background,
            ),
    );
  }
}

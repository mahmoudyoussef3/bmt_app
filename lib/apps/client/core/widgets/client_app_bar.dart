import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The client app's one and only toolbar.
///
/// Every screen header used to be assembled by hand, which drifted into four
/// different title styles, three background sources and a `centerTitle` that
/// flipped between screens. This owns those decisions instead:
///
/// - the title is **start-aligned**, because it is the only alignment that also
///   works for the [subtitle] and [leading] variants (a centred title cannot
///   share the row with an avatar), and it reads correctly under RTL;
/// - the background is the theme surface with no tint and no elevation, so a
///   scrolled list never shifts the header's colour mid-scroll;
/// - the back affordance is a [DirectionalIcon] arrow that appears only when
///   there is something to pop, so a root tab never grows a dead back button.
///
/// Screens that need a collapsing/expanding header use `ClientSliverAppBar`.
class ClientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ClientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onBack,
    this.backEnabled = true,
    this.navigationIcon,
    this.navigationTooltip,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;

  /// Secondary line under [title] — the route being booked, the office a chat
  /// belongs to. Kept to one line; it is context, not content.
  final String? subtitle;

  /// Brand mark or avatar rendered before the title block.
  final Widget? leading;

  final List<Widget>? actions;

  /// Overrides what the back arrow does. Flows that page between panes without
  /// pushing a route (packages, loyalty) use this to unwind one pane at a time.
  /// When null the arrow pops the route, and hides itself if nothing can pop.
  final VoidCallback? onBack;

  /// When false the arrow is still drawn but inert. A step that must not be
  /// abandoned mid-write (a booking being confirmed) greys out its way back
  /// rather than removing it, so the header does not reflow at the moment the
  /// rider is most likely to be watching it.
  final bool backEnabled;

  /// Glyph for the navigation slot. Defaults to a back arrow; a screen that
  /// *dismisses* rather than pops — a hosted payment page the rider abandons —
  /// passes a close icon so the gesture reads as cancelling, not stepping back.
  final IconData? navigationIcon;

  final String? navigationTooltip;

  /// Extra row below the toolbar — a wizard progress bar, a filter strip.
  final PreferredSizeWidget? bottom;

  /// Only for headers painted over their own canvas (a map, a photo). Leave
  /// null everywhere else so surfaces stay consistent.
  final Color? backgroundColor;

  final Color? foregroundColor;

  static const double toolbarHeight = kToolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  bool _showsBack(BuildContext context) =>
      onBack != null ||
      !backEnabled ||
      (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor ?? ClientColors.surfaceFor(context);
    final foreground = foregroundColor ?? ClientColors.textPrimaryFor(context);
    final isDark = ThemeData.estimateBrightnessForColor(background) ==
        Brightness.dark;

    return AppBar(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: leading != null ? 8 : null,
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      leading: _showsBack(context)
          ? IconButton(
              
              icon: navigationIcon == null
                  ? const DirectionalIcon(Icons.arrow_back_rounded)
                  : Icon(navigationIcon),
              tooltip: navigationTooltip ??
                  MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: backEnabled
                  ? (onBack ?? () => Navigator.of(context).maybePop())
                  : null,
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Flexible(
            child: ClientAppBarTitle(
              title: title,
              subtitle: subtitle,
              color: foreground,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// The title block shared by [ClientAppBar] and `ClientSliverAppBar`, so a
/// collapsing header and a fixed one are typeset identically.
class ClientAppBarTitle extends StatelessWidget {
  const ClientAppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.color,
  });

  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? ClientColors.textPrimaryFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: resolved, fontWeight: FontWeight.w800),
        ),
        if (subtitle case final String line when line.isNotEmpty)
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: resolved.withAlpha(0xB3)),
          ),
      ],
    );
  }
}

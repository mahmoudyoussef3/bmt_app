import 'dart:ui';

import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// One entry in the header's link rail.
@immutable
class LandingNavItem {
  const LandingNavItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// The sticky page header.
///
/// The design gives it one piece of state: past 24px of scroll it tightens
/// from 80px to 64px and grows a shadow. Everything else is static — the mark,
/// six anchors and the two actions.
///
/// The row is `display:flex;flex-wrap:wrap`, so the three groups fold onto
/// their own lines as the viewport narrows rather than shrinking. The two
/// thresholds below are the widths at which the browser would wrap: the link
/// rail's `flex-basis` first, then the actions.
class LandingHeader extends StatelessWidget {
  const LandingHeader({
    super.key,
    required this.links,
    required this.scrolled,
    required this.onSignIn,
    required this.onGetStarted,
    this.activeIndex = 0,
  });

  final List<LandingNavItem> links;
  final int activeIndex;
  final bool scrolled;
  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;

  static const _oneRow = 1000.0;
  static const _twoRows = 430.0;

  @override
  Widget build(BuildContext context) {
    final Widget rail = _NavRail(links: links, activeIndex: activeIndex);
    final Widget actions = _HeaderActions(
      onSignIn: onSignIn,
      onGetStarted: onGetStarted,
    );
    const Widget mark = _HeaderMark();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          // The whole tightening — the shadow, the padding and the row's own
          // height — runs on one duration, or the header appears to settle in
          // three separate steps as the reader leaves the fold.
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: const Border(
              bottom: BorderSide(color: LandingPalette.border),
            ),
            boxShadow: scrolled
                ? const [
                    BoxShadow(
                      color: Color(0x8C0B1B34),
                      offset: Offset(0, 10),
                      blurRadius: 28,
                      spreadRadius: -22,
                    ),
                  ]
                : null,
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(vertical: scrolled ? 8 : 12),
            child: LandingContainer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                constraints: BoxConstraints(
                  minHeight: (scrolled ? 64 : 80) - (scrolled ? 16 : 24),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // A [Wrap] rather than a [Row] below the widest tier: the
                    // groups fold onto their own lines the way the design's
                    // `flex-wrap` does, and a group is capped at the line
                    // width so a face wider than Cairo shortens the wordmark
                    // instead of running off the edge.
                    Widget capped(Widget child) => ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: child,
                    );

                    if (width >= _oneRow) {
                      return Row(
                        children: [
                          mark,
                          const SizedBox(width: 20),
                          Expanded(child: rail),
                          const SizedBox(width: 20),
                          actions,
                        ],
                      );
                    }
                    if (width >= _twoRows) {
                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          capped(mark),
                          capped(actions),
                          SizedBox(width: width, child: rail),
                        ],
                      );
                    }
                    // Three stacked lines, each starting where a wrapped
                    // flex line would: at the start edge, with the link rail
                    // spanning the width so it can centre its own links.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        capped(mark),
                        const SizedBox(height: 12),
                        SizedBox(width: width, child: rail),
                        const SizedBox(height: 12),
                        capped(actions),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The brand tile and wordmark.
class _HeaderMark extends StatelessWidget {
  const _HeaderMark({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // A CSS gradient angle is physical: `140deg` runs down and to the
            // right whatever the page's direction, so this stays on
            // [Alignment] rather than [AlignmentDirectional].
            gradient: onDark
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [LandingPalette.brand, LandingPalette.navy],
                  ),
            color: onDark ? Colors.white.withValues(alpha: 0.12) : null,
            border: onDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                : null,
            boxShadow: onDark
                ? null
                : [
                    BoxShadow(
                      color: LandingPalette.brand.withValues(alpha: 0.6),
                      offset: const Offset(0, 8),
                      blurRadius: 18,
                      spreadRadius: -8,
                    ),
                  ],
          ),
          child: Icon(
            Icons.directions_bus_rounded,
            size: onDark ? 22 : 23,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 11),
        // The wordmark is the only part of the mark that can be squeezed, so
        // it is the part that flexes — the tile keeps its 42px either way.
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LandingContent.brandName,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.metric(
                  19,
                  color: onDark ? Colors.white : LandingPalette.ink,
                ).copyWith(letterSpacing: -0.4, height: 1.05),
              ),
              Text(
                LandingContent.brandFullName,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(
                  10.5,
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : LandingPalette.muted,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The brand mark as the footer wears it — a translucent tile on navy.
class LandingFooterMark extends StatelessWidget {
  const LandingFooterMark({super.key});

  @override
  Widget build(BuildContext context) => const _HeaderMark(onDark: true);
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.links, required this.activeIndex});

  final List<LandingNavItem> links;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: [
        for (var i = 0; i < links.length; i++)
          _NavLink(item: links[i], active: i == activeIndex),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.item, required this.active});

  final LandingNavItem item;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Semantics(
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.item.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered ? LandingPalette.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.label(
                13.5,
                color: active || _hovered
                    ? LandingPalette.ink
                    : LandingPalette.muted,
                weight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.onSignIn, required this.onGetStarted});

  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: LandingButton(
            label: LandingContent.signIn,
            onPressed: onSignIn,
            style: LandingButtonStyle.secondary,
            height: 42,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: LandingButton(
            label: LandingContent.getStarted,
            onPressed: onGetStarted,
            height: 42,
          ),
        ),
      ],
    );
  }
}

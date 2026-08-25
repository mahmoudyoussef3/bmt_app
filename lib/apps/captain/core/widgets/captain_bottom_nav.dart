import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

class CaptainNavTab {
  const CaptainNavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// The design's tab bar: a flat, full-width band on `--surface`, separated from
/// the page by a single `--border` hairline.
///
/// It used to be a floating blurred pill with a tinted capsule around the
/// active tab. That spent a rounded card, a shadow and a coloured fill on
/// navigation — chrome outranking the trip above it — and the capsule made the
/// active tab jump width as the label changed. Here the active tab is stated
/// twice and cheaply: the icon and its label turn brand blue and the label goes
/// to w800. Nothing moves when the tab changes.
class CaptainBottomNav extends StatelessWidget {
  const CaptainBottomNav({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  static const double barHeight = 62;

  /// How much bottom padding a scrolling tab page has to reserve.
  ///
  /// The shell runs with `extendBody: true`, so a page that under-reserves
  /// paints its last card's action underneath the bar. The extra [s16] is the
  /// breathing room between that last card and the hairline.
  static double reservedSpace(BuildContext context) =>
      barHeight +
      CaptainDesignTokens.s16 +
      MediaQuery.viewPaddingOf(context).bottom;

  final int currentIndex;
  final List<CaptainNavTab> tabs;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        border: Border(
          top: BorderSide(color: CaptainColors.borderFor(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    isActive: i == currentIndex,
                    onTap: () => onTabChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final CaptainNavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? CaptainColors.primaryInkFor(context)
        : CaptainColors.textSecondaryFor(context);

    return Semantics(
      selected: isActive,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? tab.activeIcon : tab.icon, size: 21, color: color),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelSmall(context).copyWith(
                  color: color,
                  letterSpacing: 0,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';

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

/// The captain shell's floating bottom navigation.
///
/// The shell runs with `extendBody: true`, so tab pages paint *underneath* this
/// bar. A scrolling page must therefore end its content with [reservedSpace] of
/// bottom padding, otherwise its last row of controls is hidden behind the bar.
class CaptainBottomNav extends StatelessWidget {
  const CaptainBottomNav({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  /// Height of the bar itself, without the margin under it or the device inset.
  static const double barHeight = 64;

  static const double _margin = CaptainDesignTokens.s16;

  /// Bottom padding a scrolling tab page must reserve to clear the bar.
  ///
  /// Covers the bar, the margin below it, the device's bottom inset, and one
  /// margin of breathing room between the content and the bar.
  static double reservedSpace(BuildContext context) =>
      barHeight + _margin * 2 + MediaQuery.viewPaddingOf(context).bottom;

  final int currentIndex;
  final List<CaptainNavTab> tabs;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_margin, 0, _margin, _margin),
        child: Container(
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br32,
            boxShadow: CaptainDesignTokens.floatingShadow(context),
          ),
          child: ClipRRect(
            borderRadius: CaptainDesignTokens.br32,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      _NavItem(
                        tab: tabs[i],
                        isActive: i == currentIndex,
                        onTap: () => onTabChanged(i),
                      ),
                  ],
                ),
              ),
            ),
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
        ? CaptainColors.primary
        : CaptainColors.textSecondaryFor(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainDesignTokens.s20,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? CaptainColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: CaptainDesignTokens.br24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? tab.activeIcon : tab.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: CaptainTypography.labelSmall(context).copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

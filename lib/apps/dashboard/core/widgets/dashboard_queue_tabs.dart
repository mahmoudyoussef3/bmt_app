import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// One pill on a [DashboardQueueTabBar].
class DashboardQueueTab {
  const DashboardQueueTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.urgent = false,
  });

  final String label;

  /// Already formatted by the module, so a tab strip never imposes a digit
  /// system on a module that has chosen another one.
  final String count;

  final bool selected;

  /// A queue that represents outstanding work. While it holds rows and is not
  /// the open tab its badge turns to the warning tone, so "٣ تنتظر قراراً"
  /// reads from the other side of the room.
  final bool urgent;

  final VoidCallback onTap;

  /// Whether the badge should raise its voice — an urgent queue with rows in
  /// it that the operator is not currently looking at.
  bool get _alerting =>
      urgent && selected == false && count != '0' && count != '٠';
}

/// The strip of queue pills each list module is worked through.
///
/// Bookings and الاشتراكات each grew their own copy of this control, and the
/// copies drifted: one tinted an urgent badge with `error`, the other with
/// `tertiary`; one counted in Western digits, the other in Arabic-Indic. Since
/// the three المبيعات modules sit next to each other in one sidebar group, the
/// drift was visible as a change of vocabulary between two neighbouring
/// screens. There is one control now, and the module supplies only its data.
class DashboardQueueTabBar extends StatelessWidget {
  const DashboardQueueTabBar({super.key, required this.tabs});

  final List<DashboardQueueTab> tabs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
              child: _QueuePill(tab: tab),
            ),
        ],
      ),
    );
  }
}

class _QueuePill extends StatelessWidget {
  const _QueuePill({required this.tab});

  final DashboardQueueTab tab;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final selected = tab.selected;
    final alerting = tab._alerting;
    final warning = context.status(AppStatusTone.warning);

    final background = selected
        ? DashboardColors.accentFill(context)
        : DashboardColors.nested(context);
    final foreground = selected
        ? DashboardColors.onHero(context)
        : DashboardColors.ink(context);
    final borderColor = selected
        ? DashboardColors.accentFill(context)
        : DashboardColors.border(context);

    final badgeFill = selected
        ? DashboardColors.onHero(context).withAlpha(46)
        : alerting
        ? warning.tint
        : DashboardColors.accentFill(context).withAlpha(28);
    final badgeInk = selected
        ? DashboardColors.onHero(context)
        : alerting
        ? warning.ink
        : DashboardColors.accentInk(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tab.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: AppTokens.motionFast,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.medium,
              AppSpacing.small,
              AppSpacing.small,
              AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tab.label,
                  style: text.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tab.count,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: badgeInk,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

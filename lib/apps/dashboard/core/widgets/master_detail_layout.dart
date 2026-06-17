import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

/// Standard dashboard list→detail scaffold (master-detail split).
///
/// Desktop (≥ [splitBreakpoint]): master and detail render side by side so the
/// operator never loses list context. Below it: detail pushes over the master
/// when present, otherwise the master is full-width.
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final int masterFlex;
  final int detailFlex;
  final double splitBreakpoint;
  final String placeholderTitle;
  final String? placeholderSubtitle;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterFlex = 2,
    this.detailFlex = 3,
    this.splitBreakpoint = AppLayout.breakpointTablet,
    this.placeholderTitle = 'اختر عنصراً لعرض التفاصيل',
    this.placeholderSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= splitBreakpoint;

        if (!isSplit) {
          return detail ?? master;
        }

        final scheme = Theme.of(context).colorScheme;
        // IntrinsicHeight bounds the Row's cross-axis so `stretch` and the
        // VerticalDivider resolve even when the host imposes unbounded height
        // (e.g. inside a SingleChildScrollView page).
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: masterFlex, child: master),
              VerticalDivider(
                width: 1,
                color: scheme.outline.withAlpha(60),
              ),
              Expanded(
                flex: detailFlex,
                child: detail ??
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      child: EmptyState(
                        title: placeholderTitle,
                        subtitle: placeholderSubtitle,
                        emoji: '👈',
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';

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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: masterFlex, child: master),
            Container(
              width: 1,
              height: 640,
              color: scheme.outline.withAlpha(60),
            ),
            Expanded(
              flex: detailFlex,
              child:
                  detail ??
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: _MasterDetailPlaceholder(
                      title: placeholderTitle,
                      subtitle: placeholderSubtitle,
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _MasterDetailPlaceholder extends StatelessWidget {
  const _MasterDetailPlaceholder({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withAlpha(115),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary.withAlpha(70)),
              ),
              child: Icon(
                Icons.manage_search_rounded,
                color: scheme.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/skeleton.dart';

class DashboardLoading extends StatelessWidget {
  final int rows;
  final bool showHeader;

  /// When false, renders a non-scrolling [Column] instead of a [ListView].
  /// Use inside an existing scroll view (e.g. nested tab content) where a
  /// scrollable would receive unbounded height and fail to lay out.
  final bool scrollable;

  const DashboardLoading({
    super.key,
    this.rows = 6,
    this.showHeader = true,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (showHeader) ...[
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 220, height: 22),
              SizedBox(height: AppSpacing.small),
              SkeletonBox(width: 420, height: 14),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
      ],
      for (var index = 0; index < rows; index++) ...[
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: const [
              SkeletonBox(width: 44, height: 44),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 14),
                    SizedBox(height: AppSpacing.small),
                    SkeletonBox(width: 220, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.small),
      ],
    ];

    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: children,
    );
  }
}

class DashboardErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const DashboardErrorState({
    super.key,
    this.title = 'تعذر تحميل البيانات',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Icon(Icons.error_outline_rounded, color: scheme.error),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "These figures are incomplete, and here is exactly what is missing."
///
/// A composition screen reads a dozen independent feeds. Failing the whole page
/// because one of them did is the wrong trade — the other eleven still answer
/// the operator's question — but so is silently rendering zeros for the feed
/// that did not, because a zero is a claim. This is the third option: show what
/// arrived, and name what did not.
class DashboardPartialDataNotice extends StatelessWidget {
  const DashboardPartialDataNotice({super.key, required this.sources});

  /// Human-readable names of the feeds that failed, e.g. `['الإيرادات']`.
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'تعذّر تحميل: ${sources.join('، ')}. باقي الأرقام محدّثة.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/skeleton.dart';

class DashboardLoading extends StatelessWidget {
  final int rows;
  final bool showHeader;

  const DashboardLoading({super.key, this.rows = 6, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
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
      ],
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

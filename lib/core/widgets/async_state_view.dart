import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

/// The four render states every cubit-backed screen can be in.
enum AsyncViewStatus { loading, error, empty, data }

/// Unified async wrapper: loading → error (with retry) → empty (with action)
/// → data. Replaces the 24 bespoke `CircularProgressIndicator` blocks and the
/// bare `Center(child: Text(message))` error states across the dashboard.
class AsyncStateView extends StatelessWidget {
  final AsyncViewStatus status;
  final Widget child;
  final Widget? loadingPlaceholder;
  final String errorMessage;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;

  const AsyncStateView({
    super.key,
    required this.status,
    required this.child,
    this.loadingPlaceholder,
    this.errorMessage = 'تعذّر تحميل البيانات',
    this.onRetry,
    this.emptyTitle = 'لا توجد بيانات',
    this.emptySubtitle,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AsyncViewStatus.loading =>
        loadingPlaceholder ?? const Center(child: CircularProgressIndicator()),
      AsyncViewStatus.error => _ErrorView(
        message: errorMessage,
        onRetry: onRetry,
      ),
      AsyncViewStatus.empty => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(title: emptyTitle, subtitle: emptySubtitle),
            if (emptyAction != null) ...[
              const SizedBox(height: AppSpacing.medium),
              emptyAction!,
            ],
          ],
        ),
      ),
      AsyncViewStatus.data => child,
    };
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
            const SizedBox(height: AppSpacing.medium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.large),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

/// Inline error state widget for the client app.
///
/// Replaces the four different ad-hoc error patterns across the codebase
/// (dialog + EmptyState + Center(Text) + snackbar) with a single consistent
/// inline card. Placed inside the scrollable content area of the failing
/// screen rather than as an overlay.
///
/// Use [ClientErrorCard.fullScreen] when the error blocks the entire screen
/// and no other content is visible.
class ClientErrorCard extends StatelessWidget {
  const ClientErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.compact = false,
  });

  /// Full-screen centered variant. Identical copy but vertically centered
  /// with larger icon for screens with no other content.
  const ClientErrorCard.fullScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  }) : compact = false;

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// Compact layout for inline use inside cards or sections.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return compact ? _CompactError(this) : _FullError(this);
  }
}

class _FullError extends StatelessWidget {
  const _FullError(this.widget);

  final ClientErrorCard widget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.error.withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  widget.retryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClientRadius.md),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactError extends StatelessWidget {
  const _CompactError(this.widget);

  final ClientErrorCard widget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scheme.error.withAlpha(isDark ? 20 : 10),
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        border: Border.all(
          color: scheme.error.withAlpha(isDark ? 40 : 30),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: widget.onRetry,
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ClientRadius.sm),
                ),
              ),
              child: Text(
                widget.retryLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

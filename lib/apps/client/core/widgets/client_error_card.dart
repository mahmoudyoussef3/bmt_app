import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

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
  })  : compact = false;

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ClientColors.journeyRedLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: ClientColors.journeyRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: ClientTypography.headingSmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(widget.retryLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: ClientColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.journeyRedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ClientColors.journeyRed.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ClientColors.journeyRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.message,
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.onJourneyRed,
              ),
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: widget.onRetry,
              style: TextButton.styleFrom(
                foregroundColor: ClientColors.journeyRed,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                textStyle: ClientTypography.labelSmall(context),
              ),
              child: Text(widget.retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

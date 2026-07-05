import 'package:flutter/material.dart';

/// Inline, dismissible error surface for captain auth forms — a calmer
/// alternative to a transient snackbar that keeps the message in context.
class CaptainAuthErrorBanner extends StatelessWidget {
  const CaptainAuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = message;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Container(
                key: const ValueKey('captain-auth-error'),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, color: scheme.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      InkResponse(
                        onTap: onDismiss,
                        radius: 20,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: scheme.error.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

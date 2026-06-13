import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_button.dart';

class AppDialogs {
  const AppDialogs._();

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String message,
    String title = 'Something went wrong',
    VoidCallback? onRetry,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppLayout.spaceLg),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(
                  AppLayout.radiusLg,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withAlpha(25),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.errorContainer.withAlpha(120),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 42,
                      color: scheme.error,
                    ),
                  ),

                  const SizedBox(height: AppLayout.spaceLg),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.heading3(
                      scheme,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppLayout.spaceMd),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      scheme,
                    ).copyWith(
                      color: scheme.onSurface.withAlpha(180),
                    ),
                  ),

                  const SizedBox(height: AppLayout.spaceXl),

                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          text: 'Dismiss',
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ),

                      if (onRetry != null) ...[
                        const SizedBox(
                          width: AppLayout.spaceMd,
                        ),

                        Expanded(
                          child: AppButton.primary(
                            text: 'Retry',
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onRetry();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            padding: const EdgeInsets.all(
              AppLayout.spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 42,
                  color: scheme.primary,
                ),

                const SizedBox(
                  height: AppLayout.spaceLg,
                ),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3(
                    scheme,
                  ),
                ),

                const SizedBox(
                  height: AppLayout.spaceMd,
                ),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    scheme,
                  ),
                ),

                const SizedBox(
                  height: AppLayout.spaceXl,
                ),

                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        text: cancelText,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                      ),
                    ),

                    const SizedBox(
                      width: AppLayout.spaceMd,
                    ),

                    Expanded(
                      child: AppButton.primary(
                        text: confirmText,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
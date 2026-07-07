import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// Consistent success / warning / error feedback banners.
///
/// Centralises SnackBar styling so every screen confirms the outcome of an
/// action the same way — the user always sees whether their request
/// succeeded, partially succeeded, or failed.
class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) => _show(
    context,
    message,
    icon: Icons.check_circle_rounded,
    background: AppStatusColors.successContainer,
    foreground: AppStatusColors.onSuccessContainer,
  );

  static void warning(BuildContext context, String message) => _show(
    context,
    message,
    icon: Icons.warning_amber_rounded,
    background: AppStatusColors.warningContainer,
    foreground: AppStatusColors.onWarningContainer,
  );

  static void error(BuildContext context, String message) => _show(
    context,
    message,
    icon: Icons.error_outline_rounded,
    background: AppStatusColors.errorContainer,
    foreground: AppStatusColors.onErrorContainer,
  );

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          backgroundColor: background,
          content: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

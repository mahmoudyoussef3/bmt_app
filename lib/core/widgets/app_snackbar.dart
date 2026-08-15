import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// Consistent success / warning / error feedback banners.
///
/// Centralises SnackBar styling so every screen confirms the outcome of an
/// action the same way — the user always sees whether their request
/// succeeded, partially succeeded, or failed.
///
/// The three tones resolve through [AppStatusStyle] rather than reading
/// [AppStatusColors] directly: those constants are the **light** halves, so a
/// failed action used to float a `#FEE2E2` pastel card over a slate page — the
/// brightest thing on the screen, and the one the operator sees when something
/// has gone wrong.
class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) => _show(
    context,
    message,
    Icons.check_circle_rounded,
    AppStatusTone.success,
  );

  static void warning(BuildContext context, String message) => _show(
    context,
    message,
    Icons.warning_amber_rounded,
    AppStatusTone.warning,
  );

  static void error(BuildContext context, String message) =>
      _show(context, message, Icons.error_outline_rounded, AppStatusTone.error);

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    AppStatusTone tone,
  ) {
    final style = AppStatusStyle.of(context, tone);
    final background = style.tint;
    final foreground = style.ink;

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

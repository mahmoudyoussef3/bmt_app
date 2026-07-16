import 'package:flutter/material.dart';

/// The shared yes/no confirmation dialog for the captain app.
///
/// A plain `AlertDialog` with a cancel button and a colored confirm button —
/// trip completion and sign-out both hand-rolled this exact shape before
/// this existed. Use it before firing an action that can't be casually
/// undone.
class CaptainConfirmDialog {
  const CaptainConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    String cancelLabel = 'إلغاء',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

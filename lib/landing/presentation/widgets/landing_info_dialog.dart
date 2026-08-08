import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'landing_button.dart';

/// A short, honest info dialog for CTAs that have no real destination yet
/// (login, legal documents). Used instead of linking to a URL or document
/// that doesn't exist — see the login/legal notes in the navbar and footer.
class LandingInfoDialog extends StatelessWidget {
  const LandingInfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? ctaLabel,
    VoidCallback? onCta,
  }) {
    return showDialog(
      context: context,
      builder: (_) => LandingInfoDialog(
        title: title,
        message: message,
        ctaLabel: ctaLabel,
        onCta: onCta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(height: 1.6)),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.medium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        if (ctaLabel != null)
          LandingButton.primary(
            label: ctaLabel!,
            onPressed: () {
              Navigator.of(context).pop();
              onCta?.call();
            },
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import 'landing_atoms.dart';

/// A short, honest dialog for CTAs that have no real destination yet
/// (sign-in, "start with EWT", contact). Used instead of linking to a page
/// that doesn't exist — the marketing site is a standalone entry point with
/// no signed-in state to hand off to.
class LandingInfoDialog extends StatelessWidget {
  const LandingInfoDialog({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierColor: LandingPalette.navy.withValues(alpha: 0.42),
      builder: (_) => LandingInfoDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LandingPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LandingRadii.card + 4),
        side: const BorderSide(color: LandingPalette.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LandingIconSquare(
                    icon: Icons.info_outline_rounded,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: LandingType.cardTitle(17)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message, style: LandingType.cardBody(13.5)),
              const SizedBox(height: 22),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LandingButton(
                  label: 'إغلاق',
                  height: 42,
                  style: LandingButtonStyle.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

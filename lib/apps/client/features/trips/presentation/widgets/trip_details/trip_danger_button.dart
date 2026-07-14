import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The destructive action in Trip Details' bottom bar.
///
/// Cancelling used to be a `ClientButton.secondary` — a blue outlined button,
/// visually identical to the app's affirmative actions. A trip-ending action
/// has to look like one, so it carries the journey-red border and label while
/// staying quieter than a filled CTA.
class TripDangerButton extends StatelessWidget {
  const TripDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    final red = ClientColors.journeyRed;
    final tint = enabled ? red : ClientColors.textTertiaryFor(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: enabled ? red.withAlpha(14) : null,
          side: BorderSide(color: tint.withAlpha(enabled ? 110 : 60)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(tint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: ClientTypography.labelLarge(
                      context,
                    ).copyWith(color: tint),
                  ),
                ],
              )
            : Text(
                label,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(color: tint, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

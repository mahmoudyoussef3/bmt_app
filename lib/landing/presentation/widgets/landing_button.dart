import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/tokens.dart';

/// The two CTA shapes used across the landing page.
///
/// Sized for a marketing page (taller, more horizontal padding) rather than
/// [AppButton]'s in-app form-control sizing, but built on the same filled /
/// outlined split so both read as the one brand.
class LandingButton extends StatelessWidget {
  const LandingButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.dark = false,
  }) : outline = false;

  const LandingButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.dark = false,
  }) : outline = true;

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool outline;

  /// True when placed on the primary-tinted dark CTA band, where an outline
  /// button needs a light border/foreground instead of the brand color.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      ],
    );

    if (outline) {
      return SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: shape,
            foregroundColor: dark ? scheme.onPrimary : scheme.primary,
            side: BorderSide(
              color: dark ? scheme.onPrimary.withAlpha(160) : scheme.primary,
              width: 1.4,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 26),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: shape,
          backgroundColor: dark ? scheme.onPrimary : scheme.primary,
          foregroundColor: dark ? scheme.primary : scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        child: content,
      ),
    );
  }
}

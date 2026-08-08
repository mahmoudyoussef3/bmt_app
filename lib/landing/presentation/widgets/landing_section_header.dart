import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Eyebrow + headline + supporting copy, used to open every marketing
/// section. Centered by default (the shape a long-form landing page reads
/// in); pass [alignStart] for sections that sit next to a visual instead of
/// standing alone above a grid.
class LandingSectionHeader extends StatelessWidget {
  const LandingSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.alignStart = false,
    this.dark = false,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final bool alignStart;

  /// True on sections painted with the primary-tinted dark band, where the
  /// header text needs to sit on that color instead of [ColorScheme.onSurface].
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final crossAxis = alignStart
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    final textAlign = alignStart ? TextAlign.start : TextAlign.center;
    final onColor = dark ? scheme.onPrimary : scheme.onSurface;
    final mutedColor = dark
        ? scheme.onPrimary.withAlpha(200)
        : scheme.onSurfaceVariant;

    final headerEyebrow = eyebrow;
    final headerDescription = description;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        if (headerEyebrow != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: dark
                  ? scheme.onPrimary.withAlpha(28)
                  : scheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: dark
                    ? scheme.onPrimary.withAlpha(60)
                    : scheme.primary.withAlpha(60),
              ),
            ),
            child: Text(
              headerEyebrow,
              textAlign: textAlign,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: dark ? scheme.onPrimary : scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: AppTypography.heading1(
            Theme.of(context).colorScheme,
          ).copyWith(color: onColor, fontSize: 32),
        ),
        if (headerDescription != null) ...[
          const SizedBox(height: AppSpacing.small),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: alignStart ? 560 : 680,
            ),
            child: Text(
              headerDescription,
              textAlign: textAlign,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: mutedColor,
                height: 1.7,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A short colored dot used as a bullet inside body copy lists across the
/// page, kept here so every section's list reads the same way.
class LandingBullet extends StatelessWidget {
  const LandingBullet({
    super.key,
    required this.text,
    this.icon = Icons.check_circle_rounded,
    this.iconColor,
  });

  final String text;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Radius shorthand shared by the marketing-only widgets in this feature.
abstract final class LandingRadius {
  const LandingRadius._();
  static const double card = AppTokens.radiusLarge;
  static const double pill = 999;
}

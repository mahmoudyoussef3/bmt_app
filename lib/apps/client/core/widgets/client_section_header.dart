import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Standard section header for scrollable home-screen sections.
///
/// Shows a bold [title] left-aligned and an optional "See all →" link
/// right-aligned. Tapping [onSeeAll] fires the callback; the link is hidden
/// when [onSeeAll] is null.
class ClientSectionHeader extends StatelessWidget {
  const ClientSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllLabel = 'See all',
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ClientTypography.headingSmall(context)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: ClientColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
              textStyle: ClientTypography.labelMedium(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(seeAllLabel),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}

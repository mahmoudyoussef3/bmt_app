import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Standard section header for scrollable home-screen sections.
///
/// Shows a bold [title] leading and an optional "See all →" link trailing.
/// Tapping [onSeeAll] fires the callback; the link is hidden when [onSeeAll]
/// is null. Pass [seeAllLabel] to override the default localized label.
class ClientSectionHeader extends StatelessWidget {
  const ClientSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllLabel,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = seeAllLabel ?? context.l10n.home_seeAll;
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
                Text(resolvedLabel),
                const SizedBox(width: 2),
                const DirectionalIcon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}

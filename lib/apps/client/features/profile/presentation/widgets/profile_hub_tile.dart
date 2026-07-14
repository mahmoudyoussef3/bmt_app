import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// One row of the profile hub.
///
/// [value] renders the setting's current state on the right (the active
/// language, the chosen appearance) so the rider can read their preferences off
/// the hub without opening anything.
class ProfileHubTile extends StatelessWidget {
  const ProfileHubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spaceMd,
            vertical: AppLayout.spaceMd,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppLayout.spaceSm),
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppLayout.radiusMd),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: ClientColors.textPrimaryFor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.bodySmall(context).copyWith(
                          color: ClientColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppLayout.spaceSm),
                Text(
                  value!,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
              const SizedBox(width: AppLayout.spaceXs),
              Icon(
                // Material chevrons do not mirror themselves, so in Arabic the
                // affordance has to be flipped by hand or it points away from
                // the direction the screen actually opens.
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

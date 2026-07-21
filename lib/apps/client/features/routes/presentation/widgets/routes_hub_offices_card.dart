import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Entry into the office marketplace: EWT is many operators, and this is
/// where a rider browses them instead of searching by corridor.
class RoutesHubOfficesCard extends StatelessWidget {
  const RoutesHubOfficesCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return ClientCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withAlpha(18),
              borderRadius: BorderRadius.circular(ClientRadius.sm),
            ),
            child: Icon(Icons.storefront_rounded, size: 24, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.routes_officesCardTitle,
                  style: ClientTypography.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.routes_officesCardSubtitle,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: primary),
        ],
      ),
    );
  }
}

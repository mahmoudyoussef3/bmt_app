import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_avatar.dart';
import 'office_rating_row.dart';

/// One office in the marketplace directory: identity, rating, where it runs.
class OfficeCard extends StatelessWidget {
  const OfficeCard({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfficeLogoAvatar(logoUrl: office.logoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  office.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                OfficeRatingRow(office: office),
                if (office.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    office.serviceAreas.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelSmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: ClientColors.textSecondaryFor(context),
          ),
        ],
      ),
    );
  }
}

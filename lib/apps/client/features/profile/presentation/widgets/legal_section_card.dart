import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/legal_document_data.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// One numbered clause. Numbering is rendered rather than baked into the text
/// so the same content reads correctly in an RTL layout.
class LegalSectionCard extends StatelessWidget {
  const LegalSectionCard({
    super.key,
    required this.number,
    required this.section,
  });

  final int number;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ClientColors.primaryFor(context).withAlpha(30),
                  borderRadius: BorderRadius.circular(AppLayout.radiusSm),
                ),
                child: Text(
                  '$number',
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.primaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    section.title,
                    style: ClientTypography.labelLarge(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Text(
            section.body,
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_avatar.dart';
import 'office_rating_row.dart';

/// The profile masthead: who this operator is and how riders rate it.
class OfficeProfileHeader extends StatelessWidget {
  const OfficeProfileHeader({super.key, required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OfficeLogoAvatar(logoUrl: office.logoUrl, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      office.name,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    OfficeRatingRow(office: office),
                  ],
                ),
              ),
            ],
          ),
          if (office.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              office.description,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
          if (office.serviceAreas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in office.serviceAreas)
                  _ServiceAreaChip(label: area),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceAreaChip extends StatelessWidget {
  const _ServiceAreaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

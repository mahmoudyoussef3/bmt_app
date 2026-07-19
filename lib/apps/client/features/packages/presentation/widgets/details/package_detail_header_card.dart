import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import 'package_price_summary.dart';

class PackageDetailHeaderCard extends StatelessWidget {
  const PackageDetailHeaderCard({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(30),
            scheme.secondary.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: scheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  package.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: ClientSpacing.xs),
              _DaysPill(days: package.durationDays),
            ],
          ),
          const Divider(height: 24),
          PackagePriceSummary(package: package),
        ],
      ),
    );
  }
}

class _DaysPill extends StatelessWidget {
  const _DaysPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.primaryLight,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        context.l10n.packages_daysCount(days),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: ClientColors.primary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/package_plan_icon.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class PackagePlanCard extends StatelessWidget {
  const PackagePlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.highlighted = false,
  });

  final PackagePlanData plan;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (highlighted ? scheme.tertiary : scheme.primary).withAlpha(
                38,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconForPackagePlan(plan.iconKey),
              color: highlighted ? scheme.tertiary : scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppBadge(text: plan.badge),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface.withAlpha(140),
          ),
        ],
      ),
    );
  }
}

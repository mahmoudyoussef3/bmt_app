import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/package_plan_icon.dart';

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
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconForPackagePlan(plan.iconKey),
                  color: ClientColors.primary,
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
                            style: ClientTypography.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (plan.badge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ClientColors.primaryLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              plan.badge,
                              style: ClientTypography.labelSmall(context).copyWith(
                                color: ClientColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.subtitle,
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.price,
                      style: ClientTypography.priceMedium(context).copyWith(
                        color: ClientColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

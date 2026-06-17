import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/package_plan_icon.dart';

/// Clean, modern card to showcase package plans horizontally on the home screen.
class HomePackageCard extends StatelessWidget {
  const HomePackageCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.width,
  });

  final PackagePlanData plan;
  final VoidCallback onTap;
  final double width;

  static const double cardHeight = 182;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: cardHeight,
      child: Material(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClientColors.borderFor(context), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon Container & Badge Tag
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ClientColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconForPackagePlan(plan.iconKey),
                        color: ClientColors.primary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
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
                const SizedBox(height: 14),
                Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingSmall(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.subtitle.isEmpty
                      ? 'Flexible rides for repeat commutes.'
                      : plan.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Text(
                  plan.badge.isEmpty ? 'Savings vary by route' : plan.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plan.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.priceMedium(context).copyWith(
                          color: ClientColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View plan',
                      style: ClientTypography.bodySmall(context).copyWith(
                        color: ClientColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

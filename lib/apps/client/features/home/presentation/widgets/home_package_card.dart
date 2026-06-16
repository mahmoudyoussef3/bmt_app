import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/package_plan_icon.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/badge.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: cardHeight,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withAlpha(45), width: 1),
              boxShadow: [
                BoxShadow(
                  color: scheme.onSurface.withAlpha(8),
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
                        color: scheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconForPackagePlan(plan.iconKey),
                        color: scheme.primary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    if (plan.badge.isNotEmpty) AppBadge(text: plan.badge),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subheading(
                    scheme,
                  ).copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.subtitle.isEmpty
                      ? 'Flexible rides for repeat commutes.'
                      : plan.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(scheme).copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Text(
                  plan.badge.isEmpty ? 'Savings vary by route' : plan.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(scheme).copyWith(
                    color: scheme.secondary,
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
                        style: AppTextThemes.priceEmphasis(scheme).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View plan',
                      style: AppTypography.caption(scheme).copyWith(
                        color: scheme.primary,
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

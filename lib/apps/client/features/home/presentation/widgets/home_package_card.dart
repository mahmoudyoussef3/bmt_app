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

  static const double cardHeight = 158;

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
                const Spacer(),
                // Title
                Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subheading(
                    scheme,
                  ).copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                // Subtitle
                Text(
                  plan.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(scheme).copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Price + CTA Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.price,
                      style: AppTextThemes.priceEmphasis(scheme).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: scheme.primary,
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

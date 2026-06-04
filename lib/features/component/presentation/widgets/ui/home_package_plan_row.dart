import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/badge.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';

class HomePackagePlanRow extends StatelessWidget {
  const HomePackagePlanRow({
    super.key,
    required this.plan,
    required this.onTap,
    this.featured = false,
  });

  final PackagePlanData plan;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final color = featured ? scheme.tertiary : scheme.primary;

    return Material(
      color: featured ? color.withOpacity(0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: featured
                  ? color.withOpacity(0.35)
                  : scheme.outline.withOpacity(0.15),
              width: featured ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              /// ICON
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(plan.icon, color: color, size: 22),
              ),

              const SizedBox(width: 12),

              /// CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE + BADGE
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: AppTypography.subheading(scheme).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (plan.badge.isNotEmpty)
                          AppBadge(text: plan.badge),
                      ],
                    ),

                    const SizedBox(height: 4),

                    /// SUBTITLE
                    Text(
                      plan.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(scheme).copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// PRICE (moved left → better hierarchy)
                    Text(
                      plan.price,
                      style: AppTextThemes.priceEmphasis(scheme).copyWith(
                        fontSize: 15,
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              /// ARROW
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: scheme.onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
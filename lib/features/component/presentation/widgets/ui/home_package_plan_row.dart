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
    this.showDivider = true,
  });

  final PackagePlanData plan;
  final VoidCallback onTap;
  final bool featured;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = featured ? scheme.tertiary : scheme.primary;

    return Column(
      children: [
        Material(
          color: featured ? accent.withAlpha(14) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppLayout.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppLayout.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.spaceMd,
                vertical: AppLayout.spaceMd,
              ),
              child: Row(
                children: [
                  if (featured)
                    Container(
                      width: 3,
                      height: 44,
                      margin: const EdgeInsets.only(right: AppLayout.spaceSm),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(28),
                      borderRadius: BorderRadius.circular(AppLayout.radiusMd),
                    ),
                    child: Icon(plan.icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: AppLayout.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                plan.title,
                                style: AppTypography.subheading(scheme),
                              ),
                            ),
                            AppBadge(text: plan.badge),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(scheme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppLayout.spaceSm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.price,
                        style: AppTextThemes.priceEmphasis(
                          scheme,
                        ).copyWith(fontSize: 15),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: scheme.onSurface.withAlpha(130),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppLayout.spaceMd,
            endIndent: AppLayout.spaceMd,
            color: scheme.outline.withAlpha(55),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../../domain/entities/package_plan.dart';

class PackageCardPriceRow extends StatelessWidget {
  const PackageCardPriceRow({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.packages_startingPrice,
                style: textTheme.labelSmall?.copyWith(
                  color: ClientColors.textTertiaryFor(context),
                ),
              ),
              Text(
                FormatUtil.currency(context, package.priceInPounds),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: DirectionalIcon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

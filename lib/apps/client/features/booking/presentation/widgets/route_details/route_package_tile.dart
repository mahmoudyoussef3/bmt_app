import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/widgets/package_shape_chips.dart';
import 'package:bmt_app/apps/client/core/utils/client_money.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// One commute plan, quoted against the corridor the rider is looking at.
///
/// [fromPrice] is the cheapest stop pair this route prices the plan's shape at
/// — a real amount someone pays on this route, not the catalogue's flat figure
/// — so the tile leads with "from" and lets the wizard settle the exact number.
/// A plan the route does not price at all still lists, saying so plainly,
/// because its shape is still the answer to "can I commute with this office?".
class RoutePackageTile extends StatelessWidget {
  const RoutePackageTile({
    super.key,
    required this.plan,
    required this.fromPrice,
    required this.onTap,
  });

  final PackagePlan plan;
  final double? fromPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(ClientSpacing.sm),
        decoration: BoxDecoration(
          color: ClientColors.surfaceSubtleFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.md),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  PackageShapeChips(package: plan, accent: accent),
                ],
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: _Quote(price: fromPrice, accent: accent),
            ),
            const SizedBox(width: 2),
            DirectionalIcon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ClientColors.textTertiaryFor(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// "From EGP 900", or an honest note when this route prices no such plan.
class _Quote extends StatelessWidget {
  const _Quote({required this.price, required this.accent});

  final double? price;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = price;

    if (amount == null) {
      return Text(
        l10n.packages_priceAtBooking,
        textAlign: TextAlign.end,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.booking_routePackageFrom,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 1),
        Text(
          moneyLabel(amount),
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.priceSmall(context).copyWith(color: accent),
        ),
      ],
    );
  }
}

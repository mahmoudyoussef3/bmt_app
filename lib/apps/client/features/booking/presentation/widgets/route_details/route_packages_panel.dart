import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_package_pricing.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_package_tile.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The commute-plans card on Route Details: heading, one tile per plan priced
/// against this corridor, and the note that settles what "from" means.
class RoutePackagesPanel extends StatelessWidget {
  const RoutePackagesPanel({
    super.key,
    required this.route,
    required this.packages,
    required this.onSelect,
  });

  final RouteOptionData route;
  final List<PackagePlan> packages;
  final ValueChanged<PackagePlan> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(office: route.office.name),
          const SizedBox(height: 14),
          for (final plan in packages) ...[
            RoutePackageTile(
              plan: plan,
              fromPrice: routePackageFromPrice(route, plan),
              onTap: () => onSelect(plan),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            l10n.booking_routePackagesNote,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.office});

  final String office;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = ClientColors.primaryFor(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withAlpha(22),
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          child: Icon(Icons.card_membership_rounded, size: 18, color: accent),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.booking_routePackagesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.booking_routePackagesSubtitle,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              if (office.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.booking_routePackagesBy(office),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

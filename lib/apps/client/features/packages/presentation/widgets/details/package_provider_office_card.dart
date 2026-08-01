import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../../domain/entities/package_plan.dart';
import 'package_detail_section.dart';

/// The "who provides this" card on the package detail pane: seller logo, name
/// and rating, tapping through to the office's full marketplace profile — the
/// hinge that turns a package into a doorway to its office.
class PackageProviderOfficeCard extends StatelessWidget {
  const PackageProviderOfficeCard({super.key, required this.package});

  final PackagePlan package;

  /// Builds the office marketplace summary the profile route expects from the
  /// identity the package already carries — the same `public_offices` join, so
  /// this renders as full a header as opening the office from the Offices
  /// Directory. The profile then loads the seller's routes, departures and
  /// packages fresh from this id.
  OfficeSummary _asOfficeSummary() => OfficeSummary(
    id: package.officeId,
    name: package.officeName,
    logoUrl: package.officeLogoUrl,
    description: package.officeDescription,
    rating: package.officeRating,
    ratingsCount: package.officeRatingsCount,
    serviceAreas: package.officeServiceAreas,
  );

  void _openOffice(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamed(OfficesRoutes.profile, arguments: _asOfficeSummary());
  }

  @override
  Widget build(BuildContext context) {
    if (!package.hasOffice) return const SizedBox.shrink();

    final l10n = context.l10n;

    return PressableScale(
      onTap: () => _openOffice(context),
      scale: 0.98,
      child: PackageDetailSection(
        icon: Icons.storefront_outlined,
        title: l10n.packages_providedBy,
        padding: const EdgeInsets.all(ClientSpacing.sm),
        child: Row(
          children: [
            OfficeLogoAvatar(logoUrl: package.officeLogoUrl, size: 46),
            const SizedBox(width: ClientSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.officeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  _Rating(package: package),
                ],
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            // Capped so a long localized label (or a large text scale) cannot
            // starve the office name and rating beside it.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: _ViewOfficeAction(label: l10n.packages_viewOffice),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    if (!package.hasOfficeRating) {
      return Text(
        context.l10n.offices_noRatingsYet,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textSecondaryFor(context)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 15,
          color: ClientColors.ratingFor(context),
        ),
        const SizedBox(width: 3),
        // Both figures give way rather than overflow: on a narrow phone the
        // provider row can be squeezed to a few dozen pixels.
        Flexible(
          child: Text(
            package.officeRating.toStringAsFixed(1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.offices_ratingsCount(package.officeRatingsCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ],
    );
  }
}

class _ViewOfficeAction extends StatelessWidget {
  const _ViewOfficeAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(22),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: accent),
            ),
          ),
          const SizedBox(width: 3),
          DirectionalIcon(Icons.arrow_forward_rounded, size: 13, color: accent),
        ],
      ),
    );
  }
}

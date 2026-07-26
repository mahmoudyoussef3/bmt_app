import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import 'package_section_title.dart';

/// The "who provides this" card on the package detail pane: seller logo, name
/// and rating, tapping through to the office's full marketplace profile — the
/// hinge that turns a package into a doorway to its office.
class PackageProviderOfficeCard extends StatelessWidget {
  const PackageProviderOfficeCard({super.key, required this.package});

  final PackagePlan package;

  /// Builds the office marketplace summary the profile route expects from the
  /// identity the package already carries. The profile then loads the seller's
  /// routes, departures and packages fresh from this id.
  OfficeSummary _asOfficeSummary() => OfficeSummary(
    id: package.officeId,
    name: package.officeName,
    logoUrl: package.officeLogoUrl,
    rating: package.officeRating,
    ratingsCount: package.officeRatingsCount,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PackageSectionTitle(title: l10n.packages_providedBy),
        const SizedBox(height: 10),
        Material(
          color: ClientColors.surfaceSubtleFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          child: InkWell(
            onTap: () => _openOffice(context),
            borderRadius: BorderRadius.circular(ClientRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ClientRadius.lg),
                border: Border.all(color: ClientColors.borderFor(context)),
              ),
              child: Row(
                children: [
                  OfficeLogoAvatar(logoUrl: package.officeLogoUrl, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.officeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodyLarge(
                            context,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        _Rating(package: package),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ViewOfficeAction(label: l10n.packages_viewOffice),
                ],
              ),
            ),
          ),
        ),
      ],
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
        const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
        const SizedBox(width: 3),
        Text(
          package.officeRating.toStringAsFixed(1),
          style: ClientTypography.labelMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
          ),
          const SizedBox(width: 2),
          // chevron_right already declares matchTextDirection, so Flutter mirrors
          // it to point leftward — "forward" — under the app's RTL layout.
          Icon(Icons.chevron_right_rounded, size: 16, color: scheme.primary),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import 'office_brand_decor.dart';
import 'office_logo_tile.dart';
import 'office_profile_top_bar.dart';
import 'office_service_areas.dart';

/// The operator's storefront: a brand band with the company's card standing in
/// it, its logo set into the card's top edge like a crest on letterhead.
///
/// The card is the same object a rider met in the directory, promoted — so
/// following a listing into a profile feels like walking through a door rather
/// than landing on an unrelated screen.
///
/// Nothing here has a fixed height. An operator's blurb, its name and the list
/// of governorates it serves are all free text from the dashboard, and the
/// masthead this replaces cut them off at a hard-coded 340px whenever an office
/// wrote more than a sentence about itself.
class OfficeProfileHeader extends StatelessWidget {
  const OfficeProfileHeader({super.key, required this.office, this.stats});

  final OfficeSummary office;

  /// The counted stat strip, once the profile knows what this office sells.
  /// Null while it loads — the identity is drawn from arguments and is
  /// readable immediately, so the card must not wait for the network.
  final Widget? stats;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ClientRadius.xl),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: OfficeBrandDecor()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              ClientSpacing.md,
              topInset + OfficeProfileTopBar.height + ClientSpacing.xs,
              ClientSpacing.md,
              ClientSpacing.lg,
            ),
            child: _IdentityCard(office: office, stats: stats),
          ),
        ],
      ),
    );
  }
}

/// Who this operator is, how it is rated, what it sells and where it drives —
/// one card, read top to bottom in the order a rider asks.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.office, required this.stats});

  final OfficeSummary office;
  final Widget? stats;

  static const double _logoSize = 68;

  @override
  Widget build(BuildContext context) {
    final hairline = ClientColors.borderFor(context).withAlpha(150);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          // Half the crest hangs above the card; the rest of the offset is the
          // gap between the logo's bottom edge and the name.
          padding: const EdgeInsets.only(top: _logoSize / 2),
          child: ClientCard(
            padding: const EdgeInsets.fromLTRB(
              ClientSpacing.md,
              _logoSize / 2 + ClientSpacing.md,
              ClientSpacing.md,
              ClientSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  office.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: ClientSpacing.sm),
                Align(child: _RatingLine(office: office)),
                if (office.description.isNotEmpty) ...[
                  const SizedBox(height: ClientSpacing.sm),
                  Text(
                    office.description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
                if (stats != null) ...[
                  const SizedBox(height: ClientSpacing.md),
                  DashedDivider(color: hairline),
                  const SizedBox(height: ClientSpacing.xs),
                  stats!,
                ],
                if (office.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: ClientSpacing.sm),
                  DashedDivider(color: hairline),
                  const SizedBox(height: ClientSpacing.sm),
                  _ServiceAreaBlock(areas: office.serviceAreas),
                ],
              ],
            ),
          ),
        ),
        OfficeLogoTile(logoUrl: office.logoUrl, size: _logoSize),
      ],
    );
  }
}

/// The score as riders read it: the shape of the stars first, the number
/// second, the sample size last. An operator nobody has rated yet says so
/// plainly instead of showing five empty stars, which reads as zero out of five.
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!office.hasRating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ClientColors.primaryContainerFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: ClientColors.onPrimaryContainerFor(context),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.offices_noRatingsYet,
              style: ClientTypography.labelMedium(context).copyWith(
                color: ClientColors.onPrimaryContainerFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Stars(rating: office.rating),
        const SizedBox(width: 8),
        Text(
          office.rating.toStringAsFixed(1),
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.offices_ratingsCount(office.ratingsCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ),
      ],
    );
  }
}

/// Five glyphs, halved on the half-star. Laid out left-to-right in every
/// locale: a star row is a gauge, and a gauge that fills from the other end in
/// Arabic would read as a different score.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final gold = ClientColors.ratingFor(context);
    final empty = ClientColors.borderStrongFor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_rounded,
            size: 16,
            color: rating >= i - 0.5 ? gold : empty,
          ),
      ],
    );
  }
}

/// Where the operator drives, under a label — the chips alone were read as
/// filters a rider could tap.
class _ServiceAreaBlock extends StatelessWidget {
  const _ServiceAreaBlock({required this.areas});

  final List<String> areas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.offices_serves,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: ClientSpacing.xs),
        OfficeServiceAreas(areas: areas, alignment: WrapAlignment.center),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The operators trading on the marketplace, as a horizontal rail.
///
/// EWT sells several companies' seats side by side, so Home names them before
/// it lists departures: a rider who trusts one operator can go straight to
/// everything it runs instead of scanning a mixed feed for its badge. A rail
/// rather than a grid — it is a shortcut into the directory, not the directory.
class HomeOfficesRail extends StatelessWidget {
  const HomeOfficesRail({
    super.key,
    required this.offices,
    required this.isLoading,
    required this.onOpenOffice,
  });

  final List<OfficeSummary> offices;
  final bool isLoading;
  final ValueChanged<OfficeSummary> onOpenOffice;

  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _RailSkeleton();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: offices.length,
        separatorBuilder: (_, _) => const SizedBox(width: ClientSpacing.sm),
        itemBuilder: (context, index) {
          final office = offices[index];
          return _OfficeTile(office: office, onTap: () => onOpenOffice(office));
        },
      ),
    );
  }
}

/// One operator: its mark, its name, and how riders rate it — the three things
/// that decide whether a rider taps into it.
class _OfficeTile extends StatelessWidget {
  const _OfficeTile({required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: ClientCard(
        onTap: onTap,
        padding: const EdgeInsets.all(ClientSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OfficeLogoAvatar(logoUrl: office.logoUrl, size: 40),
            Text(
              office.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            _Rating(office: office),
          ],
        ),
      ),
    );
  }
}

/// Compact enough for a rail tile: an unrated newcomer says so rather than
/// showing a misleading 0.0.
class _Rating extends StatelessWidget {
  const _Rating({required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    if (!office.hasRating) {
      return Text(
        context.l10n.offices_noRatingsYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
        const SizedBox(width: 3),
        Text(
          office.rating.toStringAsFixed(1),
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.offices_ratingsCount(office.ratingsCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ),
      ],
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeOfficesRail.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: ClientSpacing.sm),
        itemBuilder: (_, _) => const SizedBox(
          width: 156,
          child: ClientSkeleton(
            height: HomeOfficesRail.height,
            borderRadius: ClientRadius.lg,
          ),
        ),
      ),
    );
  }
}

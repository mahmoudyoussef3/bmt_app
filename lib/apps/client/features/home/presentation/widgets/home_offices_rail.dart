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

  static const double height = 158;
  static const double _tileWidth = 176;

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

/// One operator, laid out the way a rider reads it: the mark and the score on
/// the top line (recognise it, trust it), the name in the middle, and where it
/// actually drives at the foot — the fact that decides whether this company is
/// any use to *this* rider.
class _OfficeTile extends StatelessWidget {
  const _OfficeTile({required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: HomeOfficesRail._tileWidth,
      child: ClientCard(
        onTap: onTap,
        padding: const EdgeInsets.all(ClientSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfficeLogoAvatar(logoUrl: office.logoUrl, size: 44),
                const Spacer(),
                _RatingPill(office: office),
              ],
            ),
            const SizedBox(height: ClientSpacing.sm),
            Text(
              office.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w800, height: 1.25),
            ),
            const Spacer(),
            _Footnote(office: office),
          ],
        ),
      ),
    );
  }
}

/// The score as a compact badge rather than a sentence: at rail scale a rider
/// compares operators at a glance, and "4.6" next to "4.2" does that where a
/// star row plus a review count does not. An unrated newcomer wears a neutral
/// "New" chip instead of a misleading 0.0.
class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    if (!office.hasRating) {
      return _Pill(
        background: ClientColors.surfaceMutedFor(context),
        child: Text(
          context.l10n.offices_new,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      );
    }

    return _Pill(
      background: ClientColors.journeyAmber.withAlpha(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            office.rating.toStringAsFixed(1),
            style: ClientTypography.labelSmall(context).copyWith(
              fontWeight: FontWeight.w900,
              color: ClientColors.onJourneyAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.background});

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: child,
    );
  }
}

/// The tile's closing line: where the operator drives when it has published
/// service areas, and how many riders scored it when it has not. One line
/// either way, so every tile in the rail ends on the same baseline.
class _Footnote extends StatelessWidget {
  const _Footnote({required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    final style = ClientTypography.labelSmall(
      context,
    ).copyWith(color: ClientColors.textSecondaryFor(context));

    if (office.serviceAreas.isEmpty) {
      return Text(
        office.hasRating
            ? context.l10n.offices_ratingsCount(office.ratingsCount)
            : context.l10n.offices_noRatingsYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Row(
      children: [
        Icon(
          Icons.place_outlined,
          size: 13,
          color: ClientColors.textTertiaryFor(context),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            office.serviceAreas.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
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
          width: HomeOfficesRail._tileWidth,
          child: ClientSkeleton(
            height: HomeOfficesRail.height,
            borderRadius: ClientRadius.lg,
          ),
        ),
      ),
    );
  }
}

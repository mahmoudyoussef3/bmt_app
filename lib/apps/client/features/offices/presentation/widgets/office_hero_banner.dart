import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../domain/entities/office_summary.dart';
import 'office_brand_decor.dart';

/// The operator's own picture, presented as a photo tile inset in its card:
/// a rounded cover shot with the company name lettered across its foot.
///
/// The tile is inset from the card's edge rather than bleeding into it, so a
/// listing reads as a stack of framed photographs — a rider scanning the
/// directory sees where one company ends and the next begins even while
/// scrolling past.
///
/// The office's uploaded picture is the only image EWT holds for it today —
/// there is no separate small logo drawn on top of it — so it is shown once,
/// large, rather than repeated as a crest elsewhere on the card. An office
/// that hasn't uploaded one yet gets the same brand gradient the rest of the
/// app uses for empty imagery (see [OfficeBrandDecor]), never a broken-image
/// glyph — a rider should never see the app's own plumbing.
///
/// The foot scrim is drawn from [ClientColors.shadowFor] rather than a flat
/// black: it is the app's own "this sits above something" tone, so text
/// reads clearly over a photo without introducing a color the rest of the
/// theme never uses.
class OfficeHeroBanner extends StatelessWidget {
  const OfficeHeroBanner({
    super.key,
    required this.office,
    required this.height,
    this.dense = false,
  });

  final OfficeSummary office;
  final double height;

  /// Tighter type and inset for the Home rail's narrower tile.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final url = office.logoUrl;
    final scrim = ClientColors.shadowFor(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        dense ? ClientRadius.sm : ClientRadius.md,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HeroPlaceholder(dense: dense),
            if (url != null && url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1],
                  colors: [Colors.transparent, scrim.withAlpha(200)],
                ),
              ),
            ),
            PositionedDirectional(
              start: dense ? 10 : 14,
              end: dense ? 10 : 14,
              bottom: dense ? 8 : 12,
              // The name leads and the check follows it inward: a rider reads
              // who this is first and is reassured second, so the mark never
              // stands between the card's edge and the company's own name.
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      office.name,
                      maxLines: dense ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (dense
                                  ? ClientTypography.labelLarge(context)
                                  : ClientTypography.headingMedium(context))
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                    ),
                  ),
                  SizedBox(width: dense ? 5 : 7),
                  _VerifiedMark(size: dense ? 15 : 19),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small brand check by the office's name — every operator on this screen
/// already passed platform onboarding before it could be listed here, so the
/// mark states a fact true of the whole directory rather than singling any
/// one office out.
class _VerifiedMark extends StatelessWidget {
  const _VerifiedMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClientColors.primaryFor(context),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(230)),
      ),
      child: Icon(Icons.check_rounded, size: size * 0.66, color: Colors.white),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          OfficeBrandDecor(scale: dense ? 0.7 : 1),
          Align(
            // Kept off the foot so it never collides with the lettered name.
            alignment: const Alignment(0, -0.35),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: dense ? 28 : 34,
              color: const Color(0x5AFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

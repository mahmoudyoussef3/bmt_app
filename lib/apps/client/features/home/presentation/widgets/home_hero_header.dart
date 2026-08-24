import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_headline.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_search_form.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_top_bar.dart';

/// Full-bleed gradient canvas at the top of home: the brand row, the
/// headline, and the route search form.
///
/// Extends behind the status bar ([topInset]) and closes on an arch that
/// stops partway down the search card, so the card straddles the curve — its
/// station rows on the gradient, its call to action on the page below. That
/// is what keeps the arch legible: it is drawn around a card sitting across
/// it, not hidden under whatever comes next.
///
/// [bottomSpace] is the clear gap left under the card before the next block.
class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.topInset,
    required this.bottomSpace,
    required this.horizontalPadding,
    required this.maxContentWidth,
    required this.onOpenNotifications,
    required this.onSearch,
  });

  final double topInset;
  final double bottomSpace;
  final double horizontalPadding;
  final double maxContentWidth;
  final VoidCallback onOpenNotifications;
  final void Function(BookingSearchQuery query) onSearch;

  /// How much of the search card hangs below the arch.
  ///
  /// Measured up from the card's bottom edge — not down from its top — so the
  /// CTA and the second station row always clear the curve, whatever the text
  /// scale does to the rows above them. Tuned so the arch crosses the card
  /// around the seam its swap disc sits on.
  static const double _cardTailBelowArch = 124;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          top: -600,
          start: 0,
          end: 0,
          height: 600,
          child: ColoredBox(color: ClientColors.heroTopFor(context)),
        ),
        _buildCanvas(context),
      ],
    );
  }

  Widget _buildCanvas(BuildContext context) {
    return Stack(
      children: [
        // The gradient is a backdrop rather than a container: it stops short
        // of the content's lower edge, and the search card's tail carries on
        // over the page background beneath the arch.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomSpace + _cardTailBelowArch,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ClientColors.heroGradientFor(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(ClientRadius.xl),
              ),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topInset + ClientSpacing.sm,
                horizontalPadding,
                bottomSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeroTopBar(onOpenNotifications: onOpenNotifications),
                  const SizedBox(height: ClientSpacing.md),
                  const HomeHeroHeadline(),
                  const SizedBox(height: ClientSpacing.md),
                  HomeHeroSearchForm(onSearch: onSearch),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

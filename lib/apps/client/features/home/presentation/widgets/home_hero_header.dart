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
/// Extends behind the status bar ([topInset]) and reserves [bottomSpace] so
/// the quick-action tiles can overlap its lower edge.
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
    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ClientRadius.xl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
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
                    HomeHeroTopBar(
                      onOpenNotifications: onOpenNotifications,
                    ),
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
      ),
    );
  }
}

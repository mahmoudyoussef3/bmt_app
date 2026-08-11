import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_destination_chips.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_greeting_row.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_search_pill.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Full-bleed gradient canvas at the top of home: greeting, notification
/// bell, the "Where to?" search pill and one-tap destination shortcuts.
///
/// Extends behind the status bar ([topInset]) and reserves [bottomSpace] so
/// the quick-action tiles can overlap its lower edge.
class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.userName,
    required this.destinations,
    required this.topInset,
    required this.bottomSpace,
    required this.horizontalPadding,
    required this.maxContentWidth,
    required this.onOpenNotifications,
    required this.onSearch,
    required this.onSelectDestination,
  });

  final String? userName;
  final List<String> destinations;
  final double topInset;
  final double bottomSpace;
  final double horizontalPadding;
  final double maxContentWidth;
  final VoidCallback onOpenNotifications;
  final VoidCallback onSearch;
  final ValueChanged<String> onSelectDestination;

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
          const PositionedDirectional(
            top: -70,
            end: -50,
            child: _HeroOrb(size: 190, opacity: 0.09),
          ),
          const PositionedDirectional(
            top: 90,
            start: -60,
            child: _HeroOrb(size: 140, opacity: 0.06),
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
                    HomeGreetingRow(
                      userName: userName,
                      onOpenNotifications: onOpenNotifications,
                    ),
                    const SizedBox(height: ClientSpacing.lg),
                    HomeSearchPill(onTap: onSearch),
                    if (destinations.isNotEmpty) ...[
                      const SizedBox(height: ClientSpacing.md),
                      Text(
                        context.l10n.home_popularDestinations,
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: Colors.white.withAlpha(160),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: ClientSpacing.xs),
                      HomeDestinationChips(
                        destinations: destinations,
                        onSelect: onSelectDestination,
                      ),
                    ],
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

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

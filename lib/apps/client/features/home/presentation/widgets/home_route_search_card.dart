import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_route_search_button.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_route_search_field.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The hero's search form: a white card holding a from/to pair with a swap
/// disc on their seam and the search CTA beneath.
///
/// The rider picks both stations here — the rows and the swap disc act in
/// place and never leave Home; only [onSearch] navigates. The card itself
/// stays presentational: [HomeHeroSearchForm] owns the pickers and the state
/// behind these values.
///
/// Its geometry follows one rule: the card's radius is a field's radius plus
/// the padding around it, so the nested corners stay concentric.
class HomeRouteSearchCard extends StatelessWidget {
  const HomeRouteSearchCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.onPickupTap,
    required this.onDestinationTap,
    required this.onSwap,
    required this.onSearch,
  });

  /// The chosen stations, empty while the rider has picked nothing.
  final String pickup;
  final String destination;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onSwap;
  final VoidCallback onSearch;

  /// Card padding and the seam between the three stacked elements — one value
  /// so the white frame around the fields reads as an even border.
  static const double _gap = ClientSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(_gap),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        boxShadow: ClientElevation.lg(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  HomeRouteSearchField(
                    icon: Icons.location_on_outlined,
                    label: l10n.common_from,
                    value: pickup,
                    placeholder: l10n.home_departureStation,
                    onTap: onPickupTap,
                  ),
                  const SizedBox(height: _gap),
                  HomeRouteSearchField(
                    icon: Icons.location_on_outlined,
                    label: l10n.common_to,
                    value: destination,
                    placeholder: l10n.home_arrivalStation,
                    onTap: onDestinationTap,
                  ),
                ],
              ),
              PositionedDirectional(
                end: _gap,
                child: _SwapButton(onTap: onSwap),
              ),
            ],
          ),
          const SizedBox(height: _gap),
          HomeRouteSearchButton(
            label: l10n.home_searchTripTitle,
            onTap: onSearch,
          ),
        ],
      ),
    );
  }
}

/// The disc straddling the seam between the two fields — tapping it flips the
/// chosen stations.
///
/// Kept the card's own surface colour rather than the brand fill: it sits on
/// the seam, so a solid brand disc would compete with the CTA directly below
/// it for the eye.
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          shape: BoxShape.circle,
          border: Border.all(color: ClientColors.borderFor(context)),
          boxShadow: ClientElevation.sm(context),
        ),
        child: Icon(
          Icons.swap_vert_rounded,
          size: 20,
          color: ClientColors.textPrimaryFor(context),
        ),
      ),
    );
  }
}

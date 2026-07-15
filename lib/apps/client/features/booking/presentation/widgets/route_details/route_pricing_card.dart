import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route Details' pricing card: starting price and full price range.
class RoutePricingCard extends StatelessWidget {
  const RoutePricingCard({super.key, required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PriceBlock(
              label: context.l10n.booking_startingPrice,
              value: route.startingPrice,
              highlighted: true,
            ),
          ),
          Container(width: 1, height: 48, color: scheme.outline.withAlpha(70)),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: _PriceBlock(
                label: context.l10n.booking_priceRange,
                value: route.priceRange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurface.withAlpha(145),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: highlighted
              ? ClientTypography.priceMedium(context).copyWith(fontSize: 21)
              : Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

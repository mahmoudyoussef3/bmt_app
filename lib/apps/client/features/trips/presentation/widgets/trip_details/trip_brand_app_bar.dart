import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The EasyWay-branded app bar shared across every Trip Details state
/// (loaded, loading, empty, error) so the screen always reads as one product.
class TripBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TripBrandAppBar({super.key, this.actions, this.title});

  final List<Widget>? actions;

  /// Falls back to the localized "Trip details" title when unset.
  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ClientColors.surfaceFor(context),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: ClientColors.primaryGradientFor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: ClientColors.textInverse,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? context.l10n.trips_detailsTitle,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
              Text(
                'EasyWay',
                style: ClientTypography.labelSmall(context).copyWith(
                  color: ClientColors.primaryFor(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: actions,
    );
  }
}

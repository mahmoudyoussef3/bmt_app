import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The EasyWay-branded app bar shared across every Trip Details state
/// (loaded, loading, empty, error) so the screen always reads as one product.
class TripBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TripBrandAppBar({super.key, this.actions, this.title});

  final List<Widget>? actions;

  /// Falls back to the localized "Trip details" title when unset.
  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(ClientAppBar.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClientAppBar(
      title: title ?? context.l10n.trips_detailsTitle,
      subtitle: 'EasyWay',
      leading: const _TripBrandMark(),
      actions: actions,
    );
  }
}

/// The product mark that distinguishes a ticket from every other detail screen.
class _TripBrandMark extends StatelessWidget {
  const _TripBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../cubit/packages_cubit.dart';
import '../cubit/packages_state.dart';

class SubscriptionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SubscriptionAppBar({super.key, required this.step});

  final SubscriptionStep step;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Back walks the flow one pane at a time, and only leaves the screen once
  /// the rider is already on the listing.
  void _onBack(BuildContext context) {
    if (context.read<PackagesCubit>().goBack()) return;
    Navigator.of(context).maybePop();
  }

  String _title(BuildContext context) => switch (step) {
    SubscriptionStep.listing => context.l10n.packages_commutePackages,
    SubscriptionStep.details => context.l10n.packages_packageDetails,
  };

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: Text(
        _title(context),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        onPressed: () => _onBack(context),
        icon: const DirectionalIcon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          tooltip: context.l10n.packages_refreshTooltip,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<PackagesCubit>().load(),
        ),
      ],
    );
  }
}

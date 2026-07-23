import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/packages_cubit.dart';
import '../cubit/packages_state.dart';

class SubscriptionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SubscriptionAppBar({super.key, required this.step});

  final SubscriptionStep step;

  @override
  Size get preferredSize => const Size.fromHeight(ClientAppBar.toolbarHeight);

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
    return ClientAppBar(
      title: _title(context),
      onBack: () => _onBack(context),
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

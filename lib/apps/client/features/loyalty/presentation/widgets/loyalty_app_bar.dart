import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';

/// Titles itself from the open panel, and its back affordance closes that panel
/// before it leaves the hub.
class LoyaltyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LoyaltyAppBar({super.key, required this.view});

  final LoyaltyView view;

  @override
  Size get preferredSize => const Size.fromHeight(ClientAppBar.toolbarHeight);

  String _title(BuildContext context) {
    final l10n = context.l10n;
    return switch (view) {
      LoyaltyView.dashboard => l10n.loyalty_titlePortal,
      LoyaltyView.history => l10n.loyalty_titleLedger,
      LoyaltyView.rewards => l10n.loyalty_titleCatalog,
    };
  }

  void _onBack(BuildContext context) {
    if (context.read<LoyaltyCubit>().popView()) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ClientAppBar(
      title: _title(context),
      onBack: () => _onBack(context),
      actions: [
        IconButton(
          tooltip: context.l10n.loyalty_refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<LoyaltyCubit>().load(),
        ),
      ],
    );
  }
}

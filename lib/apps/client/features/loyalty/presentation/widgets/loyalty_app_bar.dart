import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';

/// Titles itself from the open panel, and its back affordance closes that panel
/// before it leaves the hub.
class LoyaltyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LoyaltyAppBar({super.key, required this.view});

  final LoyaltyView view;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
    return AppBar(
      elevation: 0,
      title: Text(_title(context), style: ClientTypography.headingSmall(context)),
      leading: IconButton(
        onPressed: () => _onBack(context),
        icon: const DirectionalIcon(Icons.arrow_back_rounded),
      ),
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

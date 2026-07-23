import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Support Center app bar. The refresh action is only enabled once a
/// workspace has actually loaded — tapping it mid-load or mid-error would
/// have nothing meaningful to refresh.
class SupportCenterAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SupportCenterAppBar({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(ClientAppBar.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClientAppBar(
      title: context.l10n.support_centerTitle,
      actions: [
        BlocBuilder<SupportCubit, SupportState>(
          buildWhen: (previous, current) => current is SupportLoaded,
          builder: (context, state) => IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.l10n.support_refresh,
            onPressed: state is SupportLoaded ? onRefresh : null,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

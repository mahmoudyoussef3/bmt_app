import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: Text(
        context.l10n.support_centerTitle,
        style: ClientTypography.headingSmall(context).copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: scheme.onSurface),
      actions: [
        BlocBuilder<SupportCubit, SupportState>(
          buildWhen: (previous, current) => current is SupportLoaded,
          builder: (context, state) {
            return IconButton(
              icon: Icon(Icons.refresh_rounded, color: scheme.primary),
              tooltip: context.l10n.support_refresh,
              onPressed: state is SupportLoaded ? onRefresh : null,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

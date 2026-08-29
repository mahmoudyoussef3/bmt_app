import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_theme_cubit.dart';

/// Light/dark switch for the signed-out screens.
///
/// The console's theme control otherwise lives in Settings, behind the login —
/// so an operator on a dark-lit terminal had no way to change the one screen
/// they were actually looking at. Writes through [DashboardThemeCubit], so the
/// choice is the same persisted one Settings edits, not a screen-local flag.
///
/// Renders nothing when no [DashboardThemeCubit] is in scope: the cubit is
/// provided above `MaterialApp` in the real app, but a widget test or a visual
/// harness can mount this screen on its own.
class DashboardAuthThemeToggle extends StatelessWidget {
  const DashboardAuthThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardThemeCubit cubit;
    try {
      cubit = context.read<DashboardThemeCubit>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: () =>
          cubit.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      iconSize: 20,
      color: DashboardColors.mutedInk(context),
      tooltip: dark ? 'المظهر الفاتح' : 'المظهر الداكن',
    );
  }
}

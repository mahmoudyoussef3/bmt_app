import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../../../core/theme/dashboard_theme_cubit.dart';
import '../../../../core/widgets/dashboard_operations_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        const _SettingsHeader(),
        const SizedBox(height: AppSpacing.large),
        const SizedBox(
          height: 520,
          child: DashboardOperationsScreen(workspaceId: 'settings'),
        ),
        const SizedBox(height: AppSpacing.large),
        AppCard(
          child: BlocBuilder<DashboardThemeCubit, DashboardThemeState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مظهر اللوحة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('فاتح'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                    ],
                    selected: {
                      state.themeMode == ThemeMode.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                    },
                    onSelectionChanged: (selection) {
                      context.read<DashboardThemeCubit>().setThemeMode(
                        selection.first,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الإعدادات', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'إعدادات عامة للوحة التشغيل.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

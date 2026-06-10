import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';

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
        const SizedBox(height: AppSpacing.large),
        AppCard(
          child: BlocBuilder<AppModeCubit, AppModeState>(
            builder: (context, state) {
              final cubit = context.read<AppModeCubit>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وضع التطبيق (للمطورين)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'التبديل بين إصدارات التطبيق المختلفة (العميل، السائق، لوحة التحكم)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SegmentedButton<AppMode>(
                    segments: AppMode.values.map((m) {
                      String label = m.displayLabel;
                      switch (m) {
                        case AppMode.client:
                          label = 'العميل';
                          break;
                        case AppMode.driver:
                          label = 'السائق';
                          break;
                        case AppMode.admin:
                          label = 'المدير';
                          break;
                        case AppMode.ops:
                          label = 'لوحة التحكم';
                          break;
                      }
                      return ButtonSegment<AppMode>(
                        value: m,
                        label: Text(label),
                      );
                    }).toList(),
                    selected: {state.mode},
                    onSelectionChanged: (selection) {
                      if (selection.first != state.mode) {
                        cubit.changeMode(selection.first);
                      }
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

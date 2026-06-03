import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  final void Function(String route, [Object? arguments]) onOpenRoute;

  const ProfileScreen({super.key, required this.onOpenRoute});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppAvatar(initials: 'AH', radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ahmed Hassan',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Employee commute account',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurface.withAlpha(170),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const AppBadge(text: 'Premium access'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Access', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Driver Version',
                outline: true,
                onPressed: () => _openVersion(context, AppMode.driver),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Admin Version',
                outline: true,
                onPressed: () => _openVersion(context, AppMode.admin),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Ops Version',
                outline: true,
                onPressed: () => _openVersion(context, AppMode.ops),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Client Home',
                outline: true,
                onPressed: () => _openVersion(context, AppMode.client),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: const [
              _InfoRow(title: 'Employee ID', value: 'EMP-2047'),
              AppSeparator(),
              _InfoRow(title: 'Department', value: 'Operations'),
              AppSeparator(),
              _InfoRow(title: 'Route', value: 'Banha → Smart Village'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          onTap: () => onOpenRoute('/settings'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings & Preferences', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('General, Security, Privacy, Languages...', style: TextStyle(fontSize: 10, color: scheme.onSurface.withAlpha(150))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withAlpha(120)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Dev-only version switcher
        Builder(
          builder: (context) {
            Widget devPanel = const SizedBox.shrink();
            assert(() {
              devPanel = const _DevVersionSwitcher();
              return true;
            }());
            return devPanel;
          },
        ),
      ],
    );
  }

  void _openVersion(BuildContext context, AppMode mode) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(mode.routePath, (_) => false);
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DevVersionSwitcher extends StatelessWidget {
  const _DevVersionSwitcher();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppModeCubit>();
    final current = cubit.state.mode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Mode Switcher (Dev Only)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final modes = AppMode.values.where((mode) => mode != current);

              if (isNarrow) {
                return Column(
                  children: modes
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: m.displayLabel,
                              outline: true,
                              onPressed: () async => cubit.changeMode(m),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppMode.values.map((m) {
                  final active = m == current;
                  return FilterChip(
                    label: Text(m.displayLabel),
                    selected: active,
                    showCheckmark: false,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) async {
                      if (!active) await cubit.changeMode(m);
                    },
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Use these controls to jump between client, driver, admin, and ops app versions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Active: ${current.displayLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

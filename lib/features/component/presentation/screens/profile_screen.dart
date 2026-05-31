import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  final void Function(String route) onOpenRoute;

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
                label: 'Driver Dashboard',
                outline: true,
                onPressed: () => onOpenRoute('/driver'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Admin Dashboard',
                outline: true,
                onPressed: () => onOpenRoute('/admin'),
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
        // Dev-only version switcher
        Builder(
          builder: (context) {
            Widget devPanel = const SizedBox.shrink();
            assert(() {
              devPanel = _DevVersionSwitcher(onOpenRoute: onOpenRoute);
              return true;
            }());
            return devPanel;
          },
        ),
      ],
    );
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
  final void Function(String route) onOpenRoute;
  const _DevVersionSwitcher({required this.onOpenRoute});

  @override
  Widget build(BuildContext context) {
    // This widget is added only in debug builds via assert()
    final cubit = context.read<AppModeCubit>();
    final current = cubit.state.mode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Mode (Dev Only)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppMode.values.map((m) {
              final active = m == current;
              return ChoiceChip(
                label: Text(_label(m)),
                selected: active,
                selectedColor: Colors.blue,
                onSelected: (_) async {
                  await cubit.changeMode(m);
                  // navigate immediately to the entry route
                  if (kDebugMode) {
                    switch (m) {
                      case AppMode.client:
                        onOpenRoute('/');
                        break;
                      case AppMode.driver:
                        onOpenRoute('/driver');
                        break;
                      case AppMode.admin:
                        onOpenRoute('/admin');
                        break;
                      case AppMode.ops:
                        onOpenRoute('/ops');
                        break;
                    }
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Switch app mode for development/testing only.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _label(AppMode m) {
    switch (m) {
      case AppMode.client:
        return 'Client Mode';
      case AppMode.driver:
        return 'Driver Mode';
      case AppMode.admin:
        return 'Admin Mode';
      case AppMode.ops:
        return 'Ops Dashboard Mode';
    }
  }
}

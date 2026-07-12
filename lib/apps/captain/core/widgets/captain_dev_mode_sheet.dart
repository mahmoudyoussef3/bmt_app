import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/app_mode/app_mode.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';

/// Development-only switcher between the platform's apps.
Future<void> showCaptainDevModeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _DevModeSheet(),
  );
}

class _DevModeSheet extends StatelessWidget {
  const _DevModeSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<AppModeCubit, AppModeState>(
        builder: (context, state) {
          final cubit = context.read<AppModeCubit>();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إعدادات المطور',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'تغيير وضع التطبيق (للتطوير فقط)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppMode.values.map((mode) {
                  final active = mode == state.mode;
                  return FilterChip(
                    label: Text(mode.displayLabel),
                    selected: active,
                    onSelected: (_) {
                      if (active) return;
                      cubit.changeMode(mode);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

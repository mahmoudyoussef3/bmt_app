import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Lets the captain pick light / dark / system appearance. Reads and writes
/// through the app-wide `CaptainThemeCubit` singleton, so the choice applies
/// immediately and survives a restart.
Future<void> showCaptainAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<CaptainThemeCubit, CaptainThemeState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المظهر',
                style: CaptainTypography.titleLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              RadioGroup<ThemeMode>(
                groupValue: state.themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    context.read<CaptainThemeCubit>().setThemeMode(mode);
                  }
                },
                child: Column(
                  children: [
                    for (final option in const [
                      (
                        ThemeMode.system,
                        'تلقائي (حسب الجهاز)',
                        Icons.brightness_auto_rounded,
                      ),
                      (ThemeMode.light, 'فاتح', Icons.light_mode_rounded),
                      (ThemeMode.dark, 'داكن', Icons.dark_mode_rounded),
                    ])
                      RadioListTile<ThemeMode>(
                        value: option.$1,
                        title: Text(option.$2),
                        secondary: Icon(option.$3),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

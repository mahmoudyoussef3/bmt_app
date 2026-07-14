import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/preference_option_tile.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Switches light / dark / system. The theme applies on tap so the rider sees
/// the result behind the sheet, and it is persisted, so it is still there
/// tomorrow.
class AppearanceSheet extends StatelessWidget {
  const AppearanceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final host = ClientAppTheme.maybeOf(context);
    final current = host?.themeMode ?? ThemeMode.system;

    return ClientBottomSheet(
      title: l10n.profile_selectTheme,
      subtitle: l10n.profile_selectThemeBody,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            mode: ThemeMode.system,
            current: current,
            icon: Icons.brightness_auto_rounded,
            label: l10n.profile_themeSystem,
            description: l10n.profile_selectThemeBody,
          ),
          const SizedBox(height: AppLayout.spaceMd),
          _option(
            context,
            mode: ThemeMode.light,
            current: current,
            icon: Icons.light_mode_rounded,
            label: l10n.profile_themeLight,
            description: l10n.profile_themeLightBody,
          ),
          const SizedBox(height: AppLayout.spaceMd),
          _option(
            context,
            mode: ThemeMode.dark,
            current: current,
            icon: Icons.dark_mode_rounded,
            label: l10n.profile_themeDark,
            description: l10n.profile_themeDarkBody,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required ThemeMode mode,
    required ThemeMode current,
    required IconData icon,
    required String label,
    required String description,
  }) {
    return PreferenceOptionTile(
      icon: Icon(icon, size: 22),
      label: label,
      description: description,
      selected: current == mode,
      onTap: () {
        ClientAppTheme.maybeOf(context)?.setThemeMode(mode);
        Navigator.of(context).pop();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_tile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_section.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Language and appearance. Each row carries its current value, so the rider
/// can read their preferences off the hub without opening anything.
class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({
    super.key,
    required this.onLanguage,
    required this.onAppearance,
  });

  final VoidCallback onLanguage;
  final VoidCallback onAppearance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSection(
      title: l10n.profile_sectionPreferences,
      children: [
        ProfileHubTile(
          icon: Icons.translate_rounded,
          title: l10n.profile_language,
          value: _languageLabel(context, l10n),
          onTap: onLanguage,
        ),
        ProfileHubTile(
          icon: Icons.contrast_rounded,
          title: l10n.profile_theme,
          value: _themeLabel(context, l10n),
          onTap: onAppearance,
        ),
      ],
    );
  }

  String _languageLabel(BuildContext context, AppLocalizations l10n) {
    final code = context.watch<LocaleCubit>().state.languageCode;
    return code == 'ar'
        ? l10n.profile_languageArabic
        : l10n.profile_languageEnglish;
  }

  String _themeLabel(BuildContext context, AppLocalizations l10n) {
    final mode = ClientAppTheme.maybeOf(context)?.themeMode ?? ThemeMode.system;
    return switch (mode) {
      ThemeMode.light => l10n.profile_themeLight,
      ThemeMode.dark => l10n.profile_themeDark,
      ThemeMode.system => l10n.profile_themeSystem,
    };
  }
}

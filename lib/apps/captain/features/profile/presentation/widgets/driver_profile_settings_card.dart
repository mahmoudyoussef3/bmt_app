import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import 'captain_appearance_sheet.dart';
import 'driver_profile_section_card.dart';

/// Captain-facing settings. Appearance is the only one today, so this reads as
/// a single row rather than a list.
class DriverProfileSettingsCard extends StatelessWidget {
  const DriverProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DriverProfileSectionCard(
      title: 'الإعدادات',
      icon: Icons.settings_rounded,
      // Scoped to themeMode: nothing else on this card reads the theme state,
      // so an unrelated emission must not rebuild the row.
      child: BlocBuilder<CaptainThemeCubit, CaptainThemeState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode,
        builder: (context, state) => _AppearanceRow(themeMode: state.themeMode),
      ),
    );
  }
}

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showCaptainAppearanceSheet(context),
      borderRadius: CaptainDesignTokens.br12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s4),
        child: Row(
          children: [
            Icon(
              Icons.dark_mode_outlined,
              size: 18,
              color: CaptainColors.textSecondaryFor(context),
            ),
            const SizedBox(width: CaptainDesignTokens.s12),
            Text(
              'المظهر',
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              _themeModeLabel(themeMode),
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s4),
            Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: CaptainColors.textSecondaryFor(context),
            ),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'فاتح',
    ThemeMode.dark => 'داكن',
    ThemeMode.system => 'تلقائي',
  };
}

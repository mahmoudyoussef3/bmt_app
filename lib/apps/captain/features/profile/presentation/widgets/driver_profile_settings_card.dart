import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_theme_cubit.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import 'captain_appearance_sheet.dart';
import 'driver_profile_sign_out_button.dart';

/// Captain-facing settings, closing with the way out of the app.
///
/// Sign-out lives here as a destructive row rather than as the full-width red
/// button that used to sit alone under the last card. Ending a shift is not the
/// profile screen's headline action, and giving it the loudest control on the
/// page invited exactly the mis-tap the confirmation dialog then had to catch.
class DriverProfileSettingsCard extends StatelessWidget {
  const DriverProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptainSectionLabel('الإعدادات'),
        CaptainListGroup(
          children: [
            // Scoped to themeMode: nothing else on this card reads the theme
            // state, so an unrelated emission must not rebuild the row.
            BlocBuilder<CaptainThemeCubit, CaptainThemeState>(
              buildWhen: (previous, current) =>
                  previous.themeMode != current.themeMode,
              builder: (context, state) =>
                  _AppearanceRow(themeMode: state.themeMode),
            ),
            CaptainListRow(
              icon: Icons.logout_rounded,
              label: 'تسجيل الخروج',
              accentColor: CaptainColors.error,
              onTap: () => confirmAndSignOut(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return CaptainListRow(
      icon: Icons.dark_mode_outlined,
      label: 'المظهر',
      value: _themeModeLabel(themeMode),
      showChevron: true,
      onTap: () => showCaptainAppearanceSheet(context),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'فاتح',
    ThemeMode.dark => 'داكن',
    ThemeMode.system => 'تلقائي',
  };
}

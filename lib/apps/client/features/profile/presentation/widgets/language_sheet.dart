import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/preference_option_tile.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Switches the app language. The choice applies immediately — including the
/// layout direction — and survives a restart, which is what makes it a setting
/// rather than a decoration.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = context.watch<LocaleCubit>().state.languageCode;

    return ClientBottomSheet(
      title: l10n.profile_selectLanguage,
      subtitle: l10n.profile_selectLanguageBody,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            code: 'en',
            label: l10n.profile_languageEnglish,
            description: 'English (US)',
            current: current,
          ),
          const SizedBox(height: AppLayout.spaceMd),
          _option(
            context,
            code: 'ar',
            label: l10n.profile_languageArabic,
            description: 'العربية (مصر)',
            current: current,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String code,
    required String label,
    required String description,
    required String current,
  }) {
    return PreferenceOptionTile(
      icon: Text(
        code.toUpperCase(),
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
      label: label,
      description: description,
      selected: current == code,
      onTap: () {
        context.read<LocaleCubit>().changeLocale(code);
        Navigator.of(context).pop();
      },
    );
  }
}

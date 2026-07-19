import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';

/// A one-tap language toggle. With only two supported languages, tapping the
/// pill switches straight to the other one and persists the choice; the label
/// shows the language you'll get, in its own script.
class WelcomeLanguageToggle extends StatelessWidget {
  const WelcomeLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final targetLabel = isArabic ? 'English' : 'العربية';

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onTap: () =>
            context.read<LocaleCubit>().changeLocale(isArabic ? 'en' : 'ar'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.pill),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                color: ClientColors.textSecondaryFor(context),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                targetLabel,
                style: ClientTypography.labelSmall(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'locale_cubit.dart';

class LanguageSwitcherWidget extends StatelessWidget {
  final bool compact;

  const LanguageSwitcherWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isArabic = locale.languageCode == 'ar';
        final scheme = Theme.of(context).colorScheme;

        if (compact) {
          return IconButton(
            onPressed: () {
              context.read<LocaleCubit>().changeLocale(isArabic ? 'en' : 'ar');
            },
            icon: Icon(
              Icons.language_rounded,
              color: scheme.onSurface,
            ),
            tooltip: isArabic ? 'English' : 'العربية',
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(AppLayout.radiusLg),
          ),
          padding: const EdgeInsets.all(AppLayout.spaceXs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOption(
                context: context,
                label: 'English',
                isSelected: !isArabic,
                onTap: () => context.read<LocaleCubit>().changeLocale('en'),
              ),
              _buildOption(
                context: context,
                label: 'العربية',
                isSelected: isArabic,
                onTap: () => context.read<LocaleCubit>().changeLocale('ar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.spaceLg,
          vertical: AppLayout.spaceSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppLayout.radiusMd),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.shadow.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.button(scheme).copyWith(
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

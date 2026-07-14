import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// A selectable option inside a preference sheet (a language, an appearance).
///
/// Selection is the action — there is no separate "apply" button, because a
/// preference that needs confirming is a preference the rider cannot preview.
class PreferenceOptionTile extends StatelessWidget {
  const PreferenceOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppLayout.spaceMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppLayout.radiusMd),
            color: selected ? accent.withAlpha(18) : null,
            border: Border.all(
              color: selected ? accent : ClientColors.borderFor(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 32, height: 32, child: Center(child: icon)),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ClientTypography.labelMedium(context)),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textTertiaryFor(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? accent
                    : ClientColors.textTertiaryFor(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

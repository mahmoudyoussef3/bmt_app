import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class CaptainRememberMeCheckbox extends StatelessWidget {
  const CaptainRememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: CaptainDesignTokens.br12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: scheme.primary,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(
                  borderRadius: CaptainDesignTokens.br8,
                ),
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تذكرني',
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: CaptainColors.textPrimaryFor(context),
                    ),
                  ),
                  Text(
                    'احفظ رقم هاتفي على هذا الجهاز',
                    style: CaptainTypography.labelSmall(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

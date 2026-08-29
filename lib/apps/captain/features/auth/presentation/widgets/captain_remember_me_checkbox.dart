import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// "Remember me", as a settings row rather than a checkbox.
///
/// A checkbox next to two lines of text reads as one item in a list of things
/// to tick; this is the only option on the screen and it is a preference that
/// persists past this session, so it takes the shape the app uses for a
/// preference — a full-width row with the state on the trailing edge. The whole
/// row is the target: a 24px checkbox is not something to aim at while holding
/// a phone in one hand.
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
    final accent = CaptainColors.primaryInkFor(context);

    return Semantics(
      toggled: value,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: CaptainDesignTokens.br12,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s4,
              vertical: CaptainDesignTokens.s8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: value
                      ? accent
                      : CaptainColors.textSecondaryFor(context),
                ),
                const SizedBox(width: CaptainDesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تذكرني',
                        style: CaptainTypography.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: CaptainColors.textPrimaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'احفظ رقم هاتفي على هذا الجهاز',
                        style: CaptainTypography.labelSmall(context).copyWith(
                          color: CaptainColors.textSecondaryFor(context),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CaptainDesignTokens.s8),
                ExcludeFocus(
                  child: Switch(
                    value: value,
                    onChanged: (checked) => onChanged(checked),
                    activeThumbColor: CaptainColors.onPrimary,
                    activeTrackColor: accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

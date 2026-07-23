import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The "Remember me" control on the sign-in form. Compact by design: it shares
/// a row with the forgot-password link, so it takes only the width of its own
/// box and label instead of a full-width list tile.
class RememberMeCheckbox extends StatelessWidget {
  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(ClientRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClientSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: ClientColors.primaryFor(context),
                side: BorderSide(
                  color: ClientColors.borderStrongFor(context),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

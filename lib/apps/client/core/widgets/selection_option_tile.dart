import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A single selectable row used by [SelectionPickerSheet] and similar list
/// pickers. Shows a leading icon, the option label, and a trailing check
/// when selected.
class SelectionOptionTile extends StatelessWidget {
  const SelectionOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? ClientColors.primaryContainerFor(context)
          : ClientColors.surfaceSubtleFor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? ClientColors.primaryFor(context)
                  : ClientColors.borderFor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: ClientColors.textTertiaryFor(context)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyLarge(context).copyWith(
                    color: isSelected
                        ? ClientColors.primaryFor(context)
                        : ClientColors.textPrimaryFor(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: ClientColors.primaryFor(context),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

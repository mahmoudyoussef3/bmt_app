import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// A labeled, single-select row of filter chips (sort order, vehicle type,
/// route type, ...). Reused by every filter sheet instead of each screen
/// styling its own `ChoiceChip`/`PopupMenuButton`.
class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<T> options;
  final String Function(T option) optionLabel;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ClientTypography.labelLarge(context)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _FilterChip(
                label: optionLabel(option),
                isSelected: option == selected,
                onTap: () => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? ClientColors.primaryFor(context)
        : ClientColors.surfaceMutedFor(context);
    final foreground = isSelected
        ? ClientColors.textInverse
        : ClientColors.textPrimaryFor(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: PressableScale(
        onTap: onTap,
        scale: 0.96,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(ClientRadius.pill),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : ClientColors.borderFor(context),
              ),
            ),
            child: Text(
              label,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

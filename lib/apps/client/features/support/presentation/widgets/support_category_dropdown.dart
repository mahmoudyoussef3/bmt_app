import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_category.dart';
import 'support_input_decoration.dart';

/// "What is this about?" — the topic picker. This is the only place a client
/// classifies a ticket now that the Support Center no longer browses by
/// category.
class SupportCategoryDropdown extends StatelessWidget {
  const SupportCategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
      decoration: supportInputDecoration(context),
      style: ClientTypography.bodyMedium(
        context,
      ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
      items: supportTicketCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

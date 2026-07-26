import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_office_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'support_input_decoration.dart';

/// "Which office is this about?" — required. This is what routes the ticket to
/// an office's dashboard: a complaint with no office reaches no one. When the
/// client links a specific booking, the backend derives the office from that
/// booking and this choice is only the fallback.
class SupportOfficeDropdown extends StatelessWidget {
  const SupportOfficeDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SupportOfficeOption> options;
  final SupportOfficeOption? value;
  final ValueChanged<SupportOfficeOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final itemStyle = ClientTypography.bodyMedium(
      context,
    ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600);

    return DropdownButtonFormField<SupportOfficeOption>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.primary),
      decoration: supportInputDecoration(context),
      style: itemStyle,
      hint: Text(
        context.l10n.support_officePlaceholder,
        style: itemStyle.copyWith(color: scheme.onSurfaceVariant),
      ),
      items: options
          .map(
            (office) => DropdownMenuItem<SupportOfficeOption>(
              value: office,
              child: Text(
                office.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: itemStyle,
              ),
            ),
          )
          .toList(),
      validator: (selected) =>
          selected == null ? context.l10n.support_officeRequired : null,
      onChanged: onChanged,
    );
  }
}

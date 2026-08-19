import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_office_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'support_input_decoration.dart';

/// "Which office is this about?" — required. This is what routes the ticket to
/// an office's dashboard: a complaint with no office reaches no one. When the
/// client links a specific booking, the backend derives the office from that
/// booking and overrides this choice — the picker is then [isLocked], showing
/// the real destination instead of offering an answer the server discards.
class SupportOfficeDropdown extends StatelessWidget {
  const SupportOfficeDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hasError = false,
    this.onRetry,
    this.isLocked = false,
  });

  final List<SupportOfficeOption> options;
  final SupportOfficeOption? value;
  final ValueChanged<SupportOfficeOption?> onChanged;

  /// Set when a linked booking already decides the office: the field shows
  /// that office and stops accepting a different answer.
  final bool isLocked;

  /// Set when the last load attempt failed and the picker is still empty —
  /// otherwise the required office field would fail silently with no way for
  /// the client to recover.
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (hasError && options.isEmpty) {
      return ClientErrorCard(
        compact: true,
        message: context.l10n.support_officeLoadError,
        retryLabel: context.l10n.common_retry,
        onRetry: onRetry,
      );
    }

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
      onChanged: isLocked ? null : onChanged,
      disabledHint: value == null
          ? null
          : Text(
              value!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: itemStyle,
            ),
    );
  }
}

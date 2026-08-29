import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// A labelled field for the signed-out screens.
///
/// The label sits *above* the input rather than floating inside it: on a login
/// form every field is filled in turn, so a floating label spends its whole
/// life in the collapsed position anyway, and a persistent label keeps the two
/// fields legible at a glance while typing.
///
/// Borders, fills and focus colour all come from
/// [DashboardAppTheme]'s `inputDecorationTheme` — nothing here restates them.
class DashboardAuthField extends StatelessWidget {
  const DashboardAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.helper,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;

  /// A standing rule the operator needs *before* they type — a password
  /// minimum, a format. Rendered under the box in muted ink and replaced by the
  /// validator's message the moment the field is wrong, so the two can never
  /// stack into a two-line contradiction.
  final String? helper;

  final bool obscureText;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: DashboardColors.ink(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

/// A rounded, elevated input used across the captain auth forms. Handles its
/// own focus highlight and (optionally) the password visibility toggle.
class CaptainAuthField extends StatefulWidget {
  const CaptainAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  @override
  State<CaptainAuthField> createState() => _CaptainAuthFieldState();
}

class _CaptainAuthFieldState extends State<CaptainAuthField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        obscureText: widget.isPassword && _obscure,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        cursorColor: scheme.primary,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}

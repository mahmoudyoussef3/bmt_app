import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

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
    this.forceLtr = false,
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

  /// Scopes LTR to the field's own content — for phone numbers and other
  /// digit strings, which read left-to-right even inside the app's ambient
  /// Arabic RTL. Arabic inputs (names) must leave this off or they render
  /// left-aligned against the rest of the form.
  final bool forceLtr;

  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  @override
  State<CaptainAuthField> createState() => _CaptainAuthFieldState();
}

class _CaptainAuthFieldState extends State<CaptainAuthField> {
  bool _obscure = true;
  bool _focused = false;

  /// Owned only when the caller didn't supply one — disposing a caller's node
  /// would pull it out from under them.
  FocusNode? _ownedNode;

  FocusNode get _node => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    _ownedNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted || _node.hasFocus == _focused) return;
    setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(
          color: _focused ? scheme.primary : scheme.outline.withAlpha(60),
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: scheme.primary.withAlpha(38),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: CaptainDesignTokens.s4),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _node,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        obscureText: widget.isPassword && _obscure,
        textDirection: widget.forceLtr ? TextDirection.ltr : null,
        textAlign: widget.forceLtr ? TextAlign.left : TextAlign.start,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        cursorColor: scheme.primary,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            widget.icon,
            color: _focused
                ? scheme.primary
                : CaptainColors.textSecondaryFor(context),
          ),
          floatingLabelStyle: TextStyle(color: scheme.primary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s16,
          ),
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

import 'package:flutter/material.dart';

import 'auth_field_decoration.dart';
import 'password_visibility_toggle.dart';

/// The auth-flow text field: a focus-aware container with a themed
/// [InputDecoration] and, for passwords, a show/hide toggle.
class PremiumAuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  const PremiumAuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.isPassword = false,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  State<PremiumAuthTextField> createState() => _PremiumAuthTextFieldState();
}

class _PremiumAuthTextFieldState extends State<PremiumAuthTextField> {
  late final FocusNode _focusNode;
  late final bool _useExternalFocusNode;

  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _useExternalFocusNode = widget.focusNode != null;
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.isPassword;
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (!_useExternalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: authFieldContainerDecoration(
        context: context,
        isFocused: _isFocused,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        obscureText: widget.isPassword ? _obscureText : false,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        cursorColor: scheme.primary,
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        decoration: authFieldInputDecoration(
          context: context,
          isFocused: _isFocused,
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.isPassword
              ? PasswordVisibilityToggle(
                  obscured: _obscureText,
                  isFocused: _isFocused,
                  onToggle: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
        ),
      ),
    );
  }
}

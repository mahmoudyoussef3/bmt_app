import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import 'auth_field_decoration.dart';
import 'password_visibility_toggle.dart';

/// One input in an auth form. Stateful only to remember whether a password is
/// currently revealed; focus styling is handled by [authFieldDecoration].
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.isPassword = false,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      obscureText: widget.isPassword && _obscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      cursorColor: ClientColors.primaryFor(context),
      style: ClientTypography.bodyMedium(context).copyWith(
        color: ClientColors.textPrimaryFor(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: authFieldDecoration(
        context: context,
        label: widget.label,
        icon: widget.icon,
        suffixIcon: widget.isPassword
            ? PasswordVisibilityToggle(
                obscured: _obscured,
                onToggle: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}

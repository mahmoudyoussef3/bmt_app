import 'package:flutter/material.dart';

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
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);

    if (!_useExternalFocusNode) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = _isFocused
        ? isDark
            ? const Color(0xFF0F172A)
            : Colors.white
        : isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: _isFocused
                ? scheme.primary
                : scheme.onSurfaceVariant.withOpacity(0.75),
            fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
          ),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: _isFocused
                ? scheme.primary
                : scheme.onSurfaceVariant.withOpacity(0.65),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  splashRadius: 22,
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _isFocused
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withOpacity(0.65),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: _border(Colors.transparent),
          enabledBorder: _border(
            isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
          ),
          focusedBorder: _border(scheme.primary, width: 2),
          errorBorder: _border(scheme.error),
          focusedErrorBorder: _border(scheme.error, width: 2),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}
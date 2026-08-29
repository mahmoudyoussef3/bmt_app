import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// One input in a captain auth form.
///
/// Three deliberate choices, all of them about a form filled in on a phone held
/// in one hand:
///
/// * **The label sits above the box, not inside it.** A floating label is a
///   label that is missing until you touch the field and then shrinks to
///   caption size — on an Arabic form where the labels are the only thing
///   telling you which box is which, the name of a field has to be readable
///   while the field is empty *and* while it is full.
/// * **Errors are the field's own state, not a line of red text under it.** The
///   box takes the danger border, the leading glyph turns, and the message is
///   drawn with an icon so it reads as belonging to this input rather than as
///   floating page text.
/// * **The chrome is the theme's.** Borders, radius and fill come from
///   `inputDecorationTheme`, so these fields cannot drift from every other
///   input in either app; this widget owns only what auth adds on top — the
///   external label, the focus tint, the clear button and the error line.
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
    this.hint,
    this.helper,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;

  final bool forceLtr;

  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  /// Shown inside the empty box — an example of the value, never a restatement
  /// of [label].
  final String? hint;

  /// One quiet line under the field. Replaced by the error while one stands, so
  /// the field never grows by two lines at once.
  final String? helper;

  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<CaptainAuthField> createState() => _CaptainAuthFieldState();
}

class _CaptainAuthFieldState extends State<CaptainAuthField> {
  bool _obscure = true;
  bool _focused = false;
  bool _hasError = false;
  bool _hasText = false;

  FocusNode? _ownedNode;

  FocusNode get _node => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _node.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    _node.removeListener(_onFocusChange);
    _ownedNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted || _node.hasFocus == _focused) return;
    setState(() => _focused = _node.hasFocus);
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (!mounted || hasText == _hasText) return;
    setState(() => _hasText = hasText);
  }

  /// Mirrors the form's verdict into local state so the *box* can carry the
  /// error too, not just the message under it.
  ///
  /// Wrapping the validator rather than polling a [FormFieldState] key is what
  /// keeps the two in step: this runs exactly when — and only when — the form
  /// validates, so the border can never contradict the text below it. The
  /// rebuild is deferred because the framework is mid-validation here.
  String? _validate(String? value) {
    final error = widget.validator?.call(value);
    final hasError = error != null;
    if (hasError != _hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && hasError != _hasError) {
          setState(() => _hasError = hasError);
        }
      });
    }
    return error;
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
    _node.requestFocus();
  }

  Color _accent(BuildContext context) {
    if (!widget.enabled) return CaptainColors.textSecondaryFor(context);
    if (_hasError) return CaptainColors.dangerFor(context);
    if (_focused) return CaptainColors.primaryInkFor(context);
    return CaptainColors.textSecondaryFor(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(
          text: widget.label,
          color: accent,
          active: _focused || _hasError,
        ),
        const SizedBox(height: CaptainDesignTokens.s8),
        TextFormField(
          controller: widget.controller,
          focusNode: _node,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.enabled ? widget.autofillHints : null,
          obscureText: widget.isPassword && _obscure,
          // A phone number, a code and a password are all strings the keyboard
          // must not "help" with: autocorrect rewrites them as they are typed
          // and the captain gets an unexplained rejection.
          autocorrect: !widget.forceLtr && !widget.isPassword,
          enableSuggestions: !widget.forceLtr && !widget.isPassword,
          textDirection: widget.forceLtr ? TextDirection.ltr : null,
          textAlign: widget.forceLtr ? TextAlign.left : TextAlign.start,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          validator: widget.validator == null ? null : _validate,
          cursorColor: CaptainColors.primaryInkFor(context),
          style: CaptainTypography.bodyLarge(context).copyWith(
            color: widget.enabled
                ? CaptainColors.textPrimaryFor(context)
                : CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
            // Digits read as a sequence, not as prose: the extra tracking is
            // what makes an 11-digit number checkable at a glance.
            letterSpacing: widget.forceLtr ? 0.6 : null,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintTextDirection: widget.forceLtr ? TextDirection.ltr : null,
            filled: true,
            fillColor: widget.enabled
                ? (_focused
                      ? CaptainColors.surfaceFor(context)
                      : CaptainColors.surfaceAltFor(context))
                : CaptainColors.surfaceAltFor(context),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: CaptainDesignTokens.s12,
                end: CaptainDesignTokens.s8,
              ),
              child: Icon(widget.icon, size: 20, color: accent),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: _Suffix(
              isPassword: widget.isPassword,
              obscured: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              // The clear button is a focused-field affordance: a permanent one
              // puts a delete control beside every filled row of a form the
              // captain has already finished.
              onClear: widget.enabled && _hasText && _focused ? _clear : null,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s12,
              vertical: CaptainDesignTokens.s16,
            ),
            // Suppressed here and drawn by [_FieldMessage] instead, so the
            // message can carry an icon and share one slot with the helper.
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            counterText: '',
          ),
        ),
        _FieldMessage(
          error: _hasError ? _errorText : null,
          helper: widget.helper,
        ),
      ],
    );
  }

  String? get _errorText => widget.validator?.call(widget.controller.text);
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.color,
    required this.active,
  });

  final String text;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: CaptainDesignTokens.s4),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        style: CaptainTypography.labelMedium(context).copyWith(
          color: active ? color : CaptainColors.textPrimaryFor(context),
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _Suffix extends StatelessWidget {
  const _Suffix({
    required this.isPassword,
    required this.obscured,
    required this.onToggleObscure,
    required this.onClear,
  });

  final bool isPassword;
  final bool obscured;
  final VoidCallback onToggleObscure;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);

    // Excluded from focus traversal on purpose: an [IconButton] that can take
    // focus pulls it off the text field the moment it is tapped, which both
    // closes the keyboard and — for the clear button, whose visibility is tied
    // to focus — makes the control vanish out from under the finger.
    if (isPassword) {
      return ExcludeFocus(
        child: IconButton(
          icon: Icon(
            obscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: muted,
          ),
          tooltip: obscured ? 'إظهار' : 'إخفاء',
          onPressed: onToggleObscure,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: onClear == null
          ? const SizedBox.shrink()
          : ExcludeFocus(
              key: const ValueKey('captain-field-clear'),
              child: IconButton(
                icon: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: muted.withValues(alpha: 0.55),
                ),
                tooltip: 'مسح',
                onPressed: onClear,
              ),
            ),
    );
  }
}

/// The one line under a field: the error while there is one, the helper
/// otherwise, and nothing at all when there is neither.
class _FieldMessage extends StatelessWidget {
  const _FieldMessage({required this.error, required this.helper});

  final String? error;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final text = error ?? helper;
    final isError = error != null;
    final color = isError
        ? CaptainColors.dangerFor(context)
        : CaptainColors.textSecondaryFor(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.topStart,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                CaptainDesignTokens.s4,
                CaptainDesignTokens.s8,
                CaptainDesignTokens.s4,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: CaptainDesignTokens.s4 + 2),
                  Expanded(
                    child: Text(
                      text,
                      style: CaptainTypography.bodySmall(context).copyWith(
                        color: color,
                        fontWeight: isError ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

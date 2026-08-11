import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The row of single-digit boxes the verification code is typed into.
///
/// ## Why it is one field, not six
///
/// Six independent [TextField]s is the obvious build and the wrong one: paste
/// puts all six digits in the first box, SMS autofill fills only the first,
/// and backspace at an empty box has to be hand-wired to walk backwards. This
/// is a single hidden input with the boxes drawn from its value — so paste,
/// autofill and backspace are all just text editing, and the boxes are display
/// only.
///
/// The row is pinned to [TextDirection.ltr]. A code is read left to right in
/// every language, and under Arabic RTL an inherited direction would fill the
/// boxes from the right — the rider would watch their digits appear in what
/// looks like reverse order.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.focusNode,
    this.enabled = true,
    this.hasError = false,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final FocusNode? focusNode;
  final bool enabled;

  /// Paints every box in the error colour. Driven by the cubit's failure, not
  /// by a form validator: a wrong code is a fact the server reports, not
  /// something the field can decide for itself.
  final bool hasError;

  /// Fired once the last digit lands, so the screen can submit without the
  /// rider reaching for a button.
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return Stack(
      alignment: Alignment.center,
      children: [
        
        SizedBox(
          height: 60,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < widget.length; index++) ...[
                  if (index > 0) const SizedBox(width: ClientSpacing.xs),
                  Flexible(
                    child: _OtpBox(
                      digit: index < value.length ? value[index] : null,
                      isActive:
                          _focusNode.hasFocus &&
                          index == value.length.clamp(0, widget.length - 1),
                      hasError: widget.hasError,
                      enabled: widget.enabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
    required this.enabled,
  });

  final String? digit;
  final bool isActive;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = switch ((hasError, isActive)) {
      (true, _) => ClientColors.journeyRedFor(context),
      (false, true) => ClientColors.primaryFor(context),
      _ => ClientColors.borderFor(context),
    };

    return AnimatedContainer(
      duration: ClientMotion.fast,
      curve: ClientMotion.curve,
      constraints: const BoxConstraints(maxWidth: 56, minHeight: 60),
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? ClientColors.surfaceFor(context)
            : ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 1.6 : 1,
        ),
      ),
      child: Text(
        digit ?? '',
        style: ClientTypography.headingMedium(context).copyWith(
          color: hasError
              ? ClientColors.journeyRedFor(context)
              : ClientColors.textPrimaryFor(context),
        ),
      ),
    );
  }
}

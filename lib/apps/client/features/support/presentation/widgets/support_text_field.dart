import 'package:flutter/material.dart';
import 'support_field_label.dart';
import 'support_input_decoration.dart';

/// A labelled create-ticket text field. Validation is length-based: a ticket
/// our agents can act on needs more than a couple of characters.
class SupportTextField extends StatelessWidget {
  const SupportTextField({
    super.key,
    required this.label,
    required this.labelHint,
    required this.controller,
    required this.hint,
    required this.emptyMessage,
    required this.minLength,
    this.maxLines = 1,
  });

  final String label;
  final String labelHint;
  final TextEditingController controller;
  final String hint;
  final String emptyMessage;
  final int minLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SupportFieldLabel(label: label, hint: labelHint),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: maxLines == 1
              ? TextInputAction.next
              : TextInputAction.newline,
          decoration: supportInputDecoration(context, hint: hint),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return emptyMessage;
            if (text.length < minLength) return 'Please add a bit more detail';
            return null;
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// The "تذكرني" row on the captain login form.
class CaptainRememberMeCheckbox extends StatelessWidget {
  const CaptainRememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: const Text('تذكرني', style: TextStyle(fontWeight: FontWeight.w700)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: scheme.primary,
    );
  }
}

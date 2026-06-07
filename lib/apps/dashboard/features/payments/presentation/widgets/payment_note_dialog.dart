import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';

class PaymentNoteDialog extends StatefulWidget {
  final void Function(String note) onSubmit;

  const PaymentNoteDialog({required this.onSubmit, super.key});

  @override
  State<PaymentNoteDialog> createState() => _PaymentNoteDialogState();
}

class _PaymentNoteDialogState extends State<PaymentNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة ملاحظة'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'الملاحظة',
            hintText: 'اكتب ملاحظة واضحة لفريق المالية',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'إلغاء',
          outline: true,
          height: 40,
          onPressed: Navigator.of(context).pop,
        ),
        const SizedBox(width: AppSpacing.xSmall),
        AppButton(
          label: 'حفظ',
          height: 40,
          onPressed: () {
            widget.onSubmit(_controller.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

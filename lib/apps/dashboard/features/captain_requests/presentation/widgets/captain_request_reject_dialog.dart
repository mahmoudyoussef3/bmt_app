import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

/// Collects a rejection reason (shown to the captain) before rejecting a
/// request. Resolves with the reason, or null if cancelled.
class CaptainRequestRejectDialog extends StatefulWidget {
  final String captainName;

  const CaptainRequestRejectDialog({super.key, required this.captainName});

  static Future<String?> show(BuildContext context, String captainName) {
    return showDialog<String>(
      context: context,
      builder: (_) => CaptainRequestRejectDialog(captainName: captainName),
    );
  }

  @override
  State<CaptainRequestRejectDialog> createState() =>
      _CaptainRequestRejectDialogState();
}

class _CaptainRequestRejectDialogState
    extends State<CaptainRequestRejectDialog> {
  final _controller = TextEditingController();
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < 3) {
      setState(() => _touched = true);
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = _touched && _controller.text.trim().length < 3
        ? 'يرجى كتابة سبب واضح للرفض'
        : null;

    return AlertDialog(
      title: Text('رفض طلب ${widget.captainName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سيظهر هذا السبب للكابتن في التطبيق.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'سبب الرفض',
              border: const OutlineInputBorder(),
              errorText: error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: _submit,
          child: const Text('رفض الطلب'),
        ),
      ],
    );
  }
}

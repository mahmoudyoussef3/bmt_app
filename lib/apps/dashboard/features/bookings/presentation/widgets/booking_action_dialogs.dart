import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Confirms approval of a submitted payment. The note is optional and recorded
/// on the booking's audit notes by `approve_payment`.
void openApprovalDialog(
  BuildContext context, {
  required String message,
  required void Function(String? note) onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _ApprovalDialog(message: message, onConfirm: onConfirm),
  );
}

/// Rejects a payment with a mandatory reason (+ optional detail). Releases the
/// held seat via `reject_payment`.
void openRejectionDialog(
  BuildContext context, {
  required String message,
  required void Function(String reason) onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _RejectionDialog(message: message, onConfirm: onConfirm),
  );
}

/// Asks the client to re-upload a clearer receipt via `request_payment_review`.
void openReuploadDialog(
  BuildContext context, {
  required String message,
  required void Function(String reason) onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _ReuploadDialog(message: message, onConfirm: onConfirm),
  );
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog({required this.message, required this.onConfirm});

  final String message;
  final void Function(String? note) onConfirm;

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActionDialogShell(
      title: 'تأكيد قبول الدفع',
      icon: Icons.check_circle_outline,
      color: AppStatusColors.onSuccessContainer,
      message: widget.message,
      confirmLabel: 'قبول الدفع',
      content: TextField(
        controller: _note,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'ملاحظة اختيارية',
          hintText: 'أضف ملاحظة للعميل أو للسجل...',
        ),
      ),
      onConfirm: () {
        final note = _note.text.trim();
        widget.onConfirm(note.isEmpty ? null : note);
        Navigator.of(context).pop();
      },
    );
  }
}

class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog({required this.message, required this.onConfirm});

  final String message;
  final void Function(String reason) onConfirm;

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  String? _reason;
  final _note = TextEditingController();
  String _error = '';

  static const _reasons = [
    'الإيصال غير واضح',
    'المبلغ غير مطابق',
    'إيصال منتهي الصلاحية',
    'رقم المرجع غير صحيح',
    'صورة مقطوعة أو ناقصة',
    'إيصال مكرر',
    'سبب آخر',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActionDialogShell(
      title: 'رفض الدفع',
      icon: Icons.warning_amber_rounded,
      color: Theme.of(context).colorScheme.error,
      message: widget.message,
      confirmLabel: 'رفض',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'سبب الرفض *'),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (value) => setState(() {
              _reason = value;
              _error = '';
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'تفاصيل إضافية',
              hintText: 'تفاصيل إضافية عن سبب الرفض...',
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      onConfirm: () {
        if (_reason == null) {
          setState(() => _error = 'يجب اختيار سبب الرفض');
          return;
        }
        final note = _note.text.trim();
        widget.onConfirm(note.isEmpty ? _reason! : '$_reason - $note');
        Navigator.of(context).pop();
      },
    );
  }
}

class _ReuploadDialog extends StatefulWidget {
  const _ReuploadDialog({required this.message, required this.onConfirm});

  final String message;
  final void Function(String reason) onConfirm;

  @override
  State<_ReuploadDialog> createState() => _ReuploadDialogState();
}

class _ReuploadDialogState extends State<_ReuploadDialog> {
  String? _reason;
  String _error = '';

  static const _reasons = [
    'الصورة غير واضحة',
    'الإيصال مقطوع',
    'التاريخ غير ظاهر',
    'المبلغ غير ظاهر',
    'يجب رفع إيصال بصيغة صحيحة',
    'سبب آخر',
  ];

  @override
  Widget build(BuildContext context) {
    return ActionDialogShell(
      title: 'طلب إعادة رفع الإيصال',
      icon: Icons.refresh_rounded,
      color: AppStatusColors.onWarningContainer,
      message: widget.message,
      confirmLabel: 'طلب إعادة رفع',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'السبب *'),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (value) => setState(() {
              _reason = value;
              _error = '';
            }),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      onConfirm: () {
        if (_reason == null) {
          setState(() => _error = 'يجب اختيار السبب');
          return;
        }
        widget.onConfirm(_reason!);
        Navigator.of(context).pop();
      },
    );
  }
}

class ActionDialogShell extends StatelessWidget {
  const ActionDialogShell({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.message,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String message;
  final Widget content;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            content,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            'إلغاء',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
      ],
    );
  }
}

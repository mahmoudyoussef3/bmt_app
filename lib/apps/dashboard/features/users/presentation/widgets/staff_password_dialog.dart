import 'package:bmt_app/core/theme/spacing.dart';
import 'package:flutter/material.dart';

/// Asks how the new password should be chosen, and returns it.
///
/// Resolves to `null` when the owner cancels, and to a string otherwise — **empty
/// meaning "generate one server-side"**. Empty rather than null for the generated case
/// because the two answers are different decisions, and collapsing them would make
/// cancelling and generating indistinguishable at the call site.
///
/// The reset itself is not run here: this dialog only collects the choice, so the
/// credential reveal that follows belongs to the screen — where it can occupy the whole
/// page, the way an unrecoverable secret has to.
Future<String?> showStaffPasswordDialog(
  BuildContext context, {
  required String username,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _StaffPasswordDialog(username: username),
  );
}

class _StaffPasswordDialog extends StatefulWidget {
  const _StaffPasswordDialog({required this.username});

  final String username;

  @override
  State<_StaffPasswordDialog> createState() => _StaffPasswordDialogState();
}

class _StaffPasswordDialogState extends State<_StaffPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _generate = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_generate && !(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_generate ? '' : _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('تعيين كلمة مرور جديدة'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'كلمة المرور الحالية لحساب «${widget.username}» ستتوقف عن العمل '
                'فوراً.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              SwitchListTile(
                value: _generate,
                onChanged: (value) => setState(() => _generate = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('توليد كلمة مرور تلقائياً'),
                subtitle: const Text('تُعرض مرة واحدة بعد التغيير.'),
              ),
              if (!_generate) ...[
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الجديدة *',
                    helperText: '10 أحرف على الأقل.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').length < 10
                      ? 'كلمة المرور 10 أحرف على الأقل'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('تغيير')),
      ],
    );
  }
}

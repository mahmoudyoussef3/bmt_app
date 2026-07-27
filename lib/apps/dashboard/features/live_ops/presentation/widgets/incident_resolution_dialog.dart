import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/trip_incident.dart';

/// What the operator decided when closing an incident.
class IncidentResolution {
  final IncidentStatus status;
  final String note;

  const IncidentResolution({required this.status, required this.note});
}

/// Asks the operator to record *what was done* before an incident leaves the
/// queue.
///
/// The note is required rather than optional on purpose: a closed incident with
/// no account of the fix is indistinguishable from one closed by a mis-click,
/// and it is the only record a supervisor has when the same captain reports the
/// same fault next week. [IncidentStatus.dismissed] asks the same question — a
/// dismissal still needs a reason.
Future<IncidentResolution?> showIncidentResolutionDialog({
  required BuildContext context,
  required TripIncident incident,
  required IncidentStatus target,
}) {
  return showDialog<IncidentResolution>(
    context: context,
    builder: (_) =>
        _IncidentResolutionDialog(incident: incident, target: target),
  );
}

class _IncidentResolutionDialog extends StatefulWidget {
  const _IncidentResolutionDialog({
    required this.incident,
    required this.target,
  });

  final TripIncident incident;
  final IncidentStatus target;

  @override
  State<_IncidentResolutionDialog> createState() =>
      _IncidentResolutionDialogState();
}

class _IncidentResolutionDialogState extends State<_IncidentResolutionDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isDismissal => widget.target == IncidentStatus.dismissed;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      IncidentResolution(status: widget.target, note: _controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isDismissal ? 'استبعاد البلاغ' : 'إغلاق البلاغ'),
      // Constrained + scrollable so the dialog never overflows on a short
      // window or at a large text scale.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.incident.type.label}'
                  '${widget.incident.routeName.isEmpty ? '' : ' · ${widget.incident.routeName}'}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.incident.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    widget.incident.description,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: _isDismissal
                        ? 'سبب الاستبعاد'
                        : 'ماذا تم لحل البلاغ؟',
                    hintText: _isDismissal
                        ? 'مثال: بلاغ مكرر — تمت معالجته في بلاغ سابق.'
                        : 'مثال: تم إرسال مركبة بديلة ونقل الركاب.',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.length < 5) {
                      return 'اكتب وصفاً موجزاً لا يقل عن ٥ أحرف.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isDismissal ? 'استبعاد' : 'تم الحل'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_draft.dart';
import '../cubit/notifications_dispatch_cubit.dart';
import '../cubit/notifications_dispatch_state.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Reusable panel that operations staff use to compose and send notifications.
/// Embed inside any dashboard screen or show as a modal bottom sheet.
class NotificationComposer extends StatefulWidget {
  const NotificationComposer({super.key, this.prefilledUserId});

  /// When provided, the composer targets this specific user.
  final String? prefilledUserId;

  @override
  State<NotificationComposer> createState() => _NotificationComposerState();
}

class _NotificationComposerState extends State<NotificationComposer> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  DashboardNotificationCategory _category =
      DashboardNotificationCategory.announcement;
  NotificationTargetApp _target = NotificationTargetApp.client;
  bool _broadcast = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledUserId != null) {
      _userIdCtrl.text = widget.prefilledUserId!;
      _broadcast = false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return BlocListener<NotificationsDispatchCubit, NotificationsDispatchState>(
      listener: _handleState,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إرسال إشعار', style: tt.titleMedium),
            const SizedBox(height: 16),
            _TargetRow(
              target: _target,
              broadcast: _broadcast,
              onTargetChange: (v) => setState(() => _target = v),
              onBroadcastChange: (v) => setState(() => _broadcast = v),
            ),
            if (!_broadcast) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _userIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'معرّف المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
            ],
            const SizedBox(height: 12),
            _CategoryDropdown(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'نص الرسالة',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 20),
            _SendButton(onTap: _submit),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final draft = NotificationDraft(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      category: _category,
      targetApp: _target,
      recipientUserId: _broadcast ? null : _userIdCtrl.text.trim(),
    );
    context.read<NotificationsDispatchCubit>().dispatch(draft);
  }

  void _handleState(BuildContext context, NotificationsDispatchState state) {
    if (state is NotificationsDispatchSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الإرسال إلى ${state.recipientCount} مستلم'),
          backgroundColor: context.status(AppStatusTone.success).accent,
        ),
      );
      _titleCtrl.clear();
      _bodyCtrl.clear();
      context.read<NotificationsDispatchCubit>().reset();
    } else if (state is NotificationsDispatchError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: context.status(AppStatusTone.error).accent,
        ),
      );
      context.read<NotificationsDispatchCubit>().reset();
    }
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.target,
    required this.broadcast,
    required this.onTargetChange,
    required this.onBroadcastChange,
  });

  final NotificationTargetApp target;
  final bool broadcast;
  final ValueChanged<NotificationTargetApp> onTargetChange;
  final ValueChanged<bool> onBroadcastChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<NotificationTargetApp>(
            initialValue: target,
            decoration: const InputDecoration(
              labelText: 'التطبيق المستهدف',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: NotificationTargetApp.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onTargetChange(v);
            },
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            const Text('إرسال جماعي', style: TextStyle(fontSize: 12)),
            Switch(value: broadcast, onChanged: onBroadcastChange),
          ],
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final DashboardNotificationCategory value;
  final ValueChanged<DashboardNotificationCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DashboardNotificationCategory>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'التصنيف',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: DashboardNotificationCategory.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsDispatchCubit, NotificationsDispatchState>(
      builder: (context, state) {
        final sending = state is NotificationsDispatchSending;
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: sending ? null : onTap,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(sending ? 'جارٍ الإرسال…' : 'إرسال إشعار'),
          ),
        );
      },
    );
  }
}

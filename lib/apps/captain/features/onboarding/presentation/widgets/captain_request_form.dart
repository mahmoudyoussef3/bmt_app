import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../../auth/presentation/widgets/captain_auth_error_banner.dart';
import '../../../auth/presentation/widgets/captain_auth_field.dart';
import '../../../auth/presentation/widgets/captain_auth_header.dart';

/// Name + phone access-request form. Submission is delegated upward to the
/// onboarding cubit; this widget only owns its inputs and validation.
class CaptainRequestForm extends StatefulWidget {
  final bool submitting;
  final String? error;
  final void Function(String name, String phone) onSubmit;

  const CaptainRequestForm({
    super.key,
    required this.submitting,
    required this.onSubmit,
    this.error,
  });

  @override
  State<CaptainRequestForm> createState() => _CaptainRequestFormState();
}

class _CaptainRequestFormState extends State<CaptainRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_nameCtrl.text.trim(), _phoneCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: widget.submitting,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CaptainAuthHeader(
              icon: Icons.badge_outlined,
              title: 'انضم كـ كابتن',
              subtitle:
                  'أدخل اسمك ورقم هاتفك لإرسال طلب الانضمام. سيراجع فريق '
                  'العمليات طلبك ويفعّل حسابك.',
            ),
            const SizedBox(height: 28),
            CaptainAuthErrorBanner(message: widget.error),
            CaptainAuthField(
              controller: _nameCtrl,
              label: 'الاسم بالكامل',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v?.trim().length ?? 0) < 3 ? 'أدخل اسمك بالكامل' : null,
            ),
            const SizedBox(height: 14),
            CaptainAuthField(
              controller: _phoneCtrl,
              label: 'رقم الهاتف',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                return digits.length < 10 ? 'أدخل رقم هاتف صحيح' : null;
              },
            ),
            const SizedBox(height: 24),
            CaptainButton(
              label: widget.submitting ? 'جارٍ الإرسال...' : 'إرسال الطلب',
              isLoading: widget.submitting,
              onPressed: widget.submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

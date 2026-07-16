import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../../auth/presentation/widgets/captain_auth_error_banner.dart';
import '../../../auth/presentation/widgets/captain_auth_field.dart';
import '../../../auth/presentation/widgets/captain_auth_header.dart';
import '../../../auth/presentation/widgets/captain_auth_reveal.dart';

/// The three stages of joining, shown above the form.
///
/// Approval is a human review by operations, not an instant sign-up, so the
/// wait is set as an expectation up front rather than discovered on the
/// pending screen after submitting.
class _RequestSteps extends StatelessWidget {
  const _RequestSteps();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _Step(index: 1, icon: Icons.edit_outlined, label: 'أرسل بياناتك'),
        _Step(
          index: 2,
          icon: Icons.fact_check_outlined,
          label: 'يراجع فريق العمليات طلبك',
        ),
        _Step(
          index: 3,
          icon: Icons.directions_bus_rounded,
          label: 'تبدأ رحلاتك',
          isLast: true,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  final int index;
  final IconData icon;
  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: scheme.primary),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: scheme.primary.withAlpha(30),
                  ),
                ),
            ],
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: 6,
                bottom: isLast ? 0 : CaptainDesignTokens.s16,
              ),
              child: Text(
                label,
                style: CaptainTypography.bodyMedium(context).copyWith(
                  color: CaptainColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            const CaptainAuthReveal(
              child: CaptainAuthHeader(
                icon: Icons.badge_outlined,
                title: 'انضم كـ كابتن',
                subtitle:
                    'أدخل اسمك ورقم هاتفك لإرسال طلب الانضمام. سيراجع فريق '
                    'العمليات طلبك ويفعّل حسابك.',
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
            const CaptainAuthReveal(order: 1, child: _RequestSteps()),
            const SizedBox(height: CaptainDesignTokens.s24),
            CaptainAuthErrorBanner(message: widget.error),
            CaptainAuthReveal(
              order: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CaptainAuthField(
                    controller: _nameCtrl,
                    label: 'الاسم بالكامل',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v?.trim().length ?? 0) < 3
                        ? 'أدخل اسمك بالكامل'
                        : null,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s12),
                  CaptainAuthField(
                    controller: _phoneCtrl,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    forceLtr: true,
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      return digits.length < 10 ? 'أدخل رقم هاتف صحيح' : null;
                    },
                  ),
                  const SizedBox(height: CaptainDesignTokens.s24),
                  CaptainButton(
                    label: widget.submitting
                        ? 'جارٍ الإرسال...'
                        : 'إرسال الطلب',
                    isLoading: widget.submitting,
                    onPressed: widget.submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

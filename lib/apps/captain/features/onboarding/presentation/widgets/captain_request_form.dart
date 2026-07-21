import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../domain/entities/captain_onboarding_models.dart';
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
    return const Column(
      children: [
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

/// Office selector, shown only when more than one office is accepting
/// applications. Styled to sit alongside [CaptainAuthField] rather than as a
/// bare dropdown.
class _OfficePicker extends StatelessWidget {
  const _OfficePicker({
    required this.offices,
    required this.value,
    required this.onChanged,
  });

  final List<OnboardingOffice> offices;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'المكتب',
        prefixIcon: Icon(Icons.apartment_outlined, color: scheme.primary),
        border: const OutlineInputBorder(
          borderRadius: CaptainDesignTokens.br12,
        ),
      ),
      items: [
        for (final o in offices)
          DropdownMenuItem(value: o.id, child: Text(o.name)),
      ],
      onChanged: onChanged,
      validator: (v) => (v == null || v.isEmpty) ? 'اختر المكتب' : null,
    );
  }
}

/// Name + phone access-request form. Submission is delegated upward to the
/// onboarding cubit; this widget only owns its inputs and validation.
///
/// When more than one office is active the applicant picks the office and
/// enters the join code that office gave them. The code is what actually
/// routes the request — the picker only narrows it down — so the server
/// rejects a mismatched pair rather than trusting the selection.
class CaptainRequestForm extends StatefulWidget {
  final bool submitting;
  final String? error;
  final List<OnboardingOffice> offices;
  final bool loadingOffices;
  final void Function(
    String name,
    String phone,
    String? officeId,
    String? officeCode,
  )
  onSubmit;

  const CaptainRequestForm({
    super.key,
    required this.submitting,
    required this.onSubmit,
    this.error,
    this.offices = const [],
    this.loadingOffices = false,
  });

  bool get requiresOfficeChoice => offices.length > 1;

  @override
  State<CaptainRequestForm> createState() => _CaptainRequestFormState();
}

class _CaptainRequestFormState extends State<CaptainRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _officeId;

  @override
  void didUpdateWidget(CaptainRequestForm old) {
    super.didUpdateWidget(old);
    // Drop a selection that is no longer on offer (office deactivated while
    // the form was open).
    if (_officeId != null &&
        !widget.offices.any((o) => o.id == _officeId)) {
      _officeId = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final needsOffice = widget.requiresOfficeChoice;
    widget.onSubmit(
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      needsOffice ? _officeId : null,
      needsOffice ? _codeCtrl.text.trim().toUpperCase() : null,
    );
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
                  if (widget.requiresOfficeChoice) ...[
                    const SizedBox(height: CaptainDesignTokens.s12),
                    _OfficePicker(
                      offices: widget.offices,
                      value: _officeId,
                      onChanged: (id) => setState(() => _officeId = id),
                    ),
                    const SizedBox(height: CaptainDesignTokens.s12),
                    CaptainAuthField(
                      controller: _codeCtrl,
                      label: 'كود المكتب',
                      icon: Icons.vpn_key_outlined,
                      textInputAction: TextInputAction.done,
                      forceLtr: true,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => (v?.trim().length ?? 0) < 4
                          ? 'أدخل كود المكتب'
                          : null,
                    ),
                    const SizedBox(height: CaptainDesignTokens.s8),
                    Text(
                      'الكود يعطيه لك المكتب عند التعاقد.',
                      style: CaptainTypography.bodySmall(context).copyWith(
                        color: CaptainColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
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

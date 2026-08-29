import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_digits.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_input_formatters.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_validators.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

import '../../domain/entities/captain_onboarding_models.dart';
import '../../../auth/presentation/widgets/captain_auth_error_banner.dart';
import '../../../auth/presentation/widgets/captain_auth_field.dart';
import '../../../auth/presentation/widgets/captain_auth_reveal.dart';
import 'captain_office_picker.dart';

/// The join request — the captain app's sign-up.
///
/// It is not an account form and is written not to read like one: nothing here
/// grants access. What the captain fills in is a request an operator will read
/// and act on, which is why the steps are stated *before* the fields rather
/// than buried in a confirmation afterwards — someone who expects to be driving
/// in five minutes should find out here that a human has to approve them first.
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

  /// One office is not a choice — the field only appears when the captain could
  /// genuinely file against the wrong employer.
  bool get requiresOfficeChoice => offices.length > 1;

  @override
  State<CaptainRequestForm> createState() => _CaptainRequestFormState();
}

class _CaptainRequestFormState extends State<CaptainRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  final _nameNode = FocusNode();
  final _phoneNode = FocusNode();
  final _codeNode = FocusNode();

  String? _officeId;

  @override
  void didUpdateWidget(CaptainRequestForm old) {
    super.didUpdateWidget(old);
    if (_officeId != null && !widget.offices.any((o) => o.id == _officeId)) {
      _officeId = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _nameNode.dispose();
    _phoneNode.dispose();
    _codeNode.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.selectionClick();

    final needsOffice = widget.requiresOfficeChoice;
    widget.onSubmit(
      _nameCtrl.text.trim(),
      CaptainDigits.only(_phoneCtrl.text),
      needsOffice ? _officeId : null,
      needsOffice ? _codeCtrl.text.trim().toUpperCase() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsOffice = widget.requiresOfficeChoice;

    return AbsorbPointer(
      absorbing: widget.submitting,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CaptainAuthReveal(child: _RequestSteps()),
            const SizedBox(height: CaptainDesignTokens.s24),
            CaptainAuthErrorBanner(message: widget.error),
            CaptainAuthReveal(
              order: 1,
              child: CaptainCard(
                elevated: true,
                padding: const EdgeInsets.all(CaptainDesignTokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CaptainAuthField(
                      controller: _nameCtrl,
                      focusNode: _nameNode,
                      label: 'الاسم بالكامل',
                      hint: 'كما هو في بطاقة الرقم القومي',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      enabled: !widget.submitting,
                      onSubmitted: (_) => _phoneNode.requestFocus(),
                      validator: CaptainValidators.fullName,
                    ),
                    const SizedBox(height: CaptainDesignTokens.s16),
                    CaptainAuthField(
                      controller: _phoneCtrl,
                      focusNode: _phoneNode,
                      label: 'رقم الهاتف',
                      hint: '01xxxxxxxxx',
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: needsOffice
                          ? TextInputAction.next
                          : TextInputAction.done,
                      forceLtr: true,
                      enabled: !widget.submitting,
                      inputFormatters: const [
                        CaptainDigitsInputFormatter(maxLength: 11),
                      ],
                      autofillHints: const [AutofillHints.telephoneNumber],
                      onSubmitted: (_) =>
                          needsOffice ? _codeNode.requestFocus() : _submit(),
                      validator: CaptainValidators.phone,
                      helper: 'ستُسجّل دخولك بهذا الرقم بعد الموافقة.',
                    ),
                  ],
                ),
              ),
            ),
            if (needsOffice) ...[
              const SizedBox(height: CaptainDesignTokens.s20),
              CaptainAuthReveal(
                order: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CaptainSectionLabel('بيانات المكتب'),
                    CaptainCard(
                      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CaptainOfficePicker(
                            offices: widget.offices,
                            value: _officeId,
                            loading: widget.loadingOffices,
                            enabled: !widget.submitting,
                            onChanged: (id) => setState(() => _officeId = id),
                          ),
                          const SizedBox(height: CaptainDesignTokens.s16),
                          CaptainAuthField(
                            controller: _codeCtrl,
                            focusNode: _codeNode,
                            label: 'كود المكتب',
                            hint: 'مثال: EWT-1024',
                            icon: Icons.vpn_key_outlined,
                            textInputAction: TextInputAction.done,
                            forceLtr: true,
                            enabled: !widget.submitting,
                            inputFormatters: const [
                              CaptainUpperCaseInputFormatter(),
                            ],
                            onSubmitted: (_) => _submit(),
                            validator: CaptainValidators.officeCode,
                            helper: 'الكود يعطيه لك المكتب عند التعاقد.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: CaptainDesignTokens.s24),
            CaptainAuthReveal(
              order: needsOffice ? 3 : 2,
              child: CaptainButton(
                label: widget.submitting ? 'جارٍ الإرسال...' : 'إرسال الطلب',
                icon: widget.submitting ? null : Icons.send_rounded,
                mirrorIconInRtl: true,
                isLoading: widget.submitting,
                onPressed: widget.submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What actually happens after "إرسال الطلب", stated up front.
class _RequestSteps extends StatelessWidget {
  const _RequestSteps();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptainSectionLabel('كيف تنضم؟'),
        CaptainCard(
          padding: const EdgeInsets.all(CaptainDesignTokens.s16),
          child: const Column(
            children: [
              _Step(icon: Icons.edit_outlined, label: 'أرسل بياناتك'),
              _Step(
                icon: Icons.fact_check_outlined,
                label: 'يراجع فريق العمليات طلبك',
              ),
              _Step(
                icon: Icons.directions_bus_rounded,
                label: 'تبدأ رحلاتك',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, this.isLast = false});

  final IconData icon;
  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = CaptainColors.primaryInkFor(context);

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
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: accent.withValues(alpha: 0.14),
                  ),
                ),
            ],
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: 7,
                bottom: isLast ? 0 : CaptainDesignTokens.s16,
              ),
              child: Text(
                label,
                style: CaptainTypography.bodyMedium(context).copyWith(
                  color: CaptainColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

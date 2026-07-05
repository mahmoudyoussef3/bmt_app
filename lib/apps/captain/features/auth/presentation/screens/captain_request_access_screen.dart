import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../widgets/captain_auth_error_banner.dart';
import '../widgets/captain_auth_field.dart';
import '../widgets/captain_auth_header.dart';
import '../widgets/captain_auth_scaffold.dart';
import '../widgets/captain_request_success_view.dart';

/// Captain "sign up" — an access request rather than a self-serve account.
///
/// Drivers are provisioned by the Dashboard (the operational source of truth),
/// so this screen submits an application for the operations team to review
/// instead of minting a live account. It exercises the full loading → success
/// → failure state surface the rest of the app follows.
class CaptainRequestAccessScreen extends StatefulWidget {
  const CaptainRequestAccessScreen({super.key});

  @override
  State<CaptainRequestAccessScreen> createState() =>
      _CaptainRequestAccessScreenState();
}

enum _SubmitStatus { idle, submitting, success }

class _CaptainRequestAccessScreenState
    extends State<CaptainRequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  _SubmitStatus _status = _SubmitStatus.idle;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _status = _SubmitStatus.submitting;
      _error = null;
    });

    // Mock submission — a real build would post this to an operations queue.
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _status = _SubmitStatus.success);
  }

  @override
  Widget build(BuildContext context) {
    final submitting = _status == _SubmitStatus.submitting;

    if (_status == _SubmitStatus.success) {
      return CaptainAuthScaffold(
        showBack: true,
        child: CaptainRequestSuccessView(
          name: _nameCtrl.text.trim(),
          onDone: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return AbsorbPointer(
      absorbing: submitting,
      child: CaptainAuthScaffold(
        showBack: true,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CaptainAuthHeader(
                icon: Icons.badge_outlined,
                title: 'Join as a Captain',
                subtitle:
                    'Apply to drive with EasyWay. Our operations team reviews '
                    'every application before activating an account.',
              ),
              const SizedBox(height: 32),
              CaptainAuthErrorBanner(
                message: _error,
                onDismiss: () => setState(() => _error = null),
              ),
              CaptainAuthField(
                controller: _nameCtrl,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v?.trim().length ?? 0) < 3 ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 14),
              CaptainAuthField(
                controller: _phoneCtrl,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  return digits.length < 10 ? 'Enter a valid phone number' : null;
                },
              ),
              const SizedBox(height: 14),
              CaptainAuthField(
                controller: _licenseCtrl,
                label: 'Driving license number',
                icon: Icons.contact_page_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => (v?.trim().length ?? 0) < 4
                    ? 'Enter your license number'
                    : null,
              ),
              const SizedBox(height: 24),
              CaptainButton(
                label: submitting ? 'Submitting...' : 'Submit application',
                isLoading: submitting,
                onPressed: submitting ? null : _submit,
              ),
              const SizedBox(height: 16),
              Text(
                'Accounts are activated by the operations team. You\'ll be '
                'notified once your application is approved.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_labeled_field.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_scaffold.dart';

enum _RegistrationFormState { empty, partial, valid, invalid }

/// Profile completion after sign-in (UI only).
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.prefilledPhone, this.viaSocial});

  final String? prefilledPhone;
  final String? viaSocial;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _touched = false;
  bool _hasPhoto = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPhone != null) {
      _phoneController.text = widget.prefilledPhone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  _RegistrationFormState get _formState {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty && email.isEmpty && phone.isEmpty) {
      return _RegistrationFormState.empty;
    }
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    final phoneOk = phone.replaceAll(RegExp(r'\D'), '').length >= 8;

    if (name.length >= 2 && emailOk && phoneOk) {
      return _RegistrationFormState.valid;
    }
    if (!_touched) {
      return name.isEmpty && email.isEmpty && phone.isEmpty
          ? _RegistrationFormState.empty
          : _RegistrationFormState.partial;
    }
    return _RegistrationFormState.invalid;
  }

  String? get _nameError {
    if (!_touched) return null;
    if (_nameController.text.trim().length < 2) {
      return 'Enter your full name (at least 2 characters)';
    }
    return null;
  }

  String? get _emailError {
    if (!_touched) return null;
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? get _phoneError {
    if (!_touched) return null;
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Enter a valid phone number';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_formState != _RegistrationFormState.valid) return;

    await context.read<ClientAuthCubit>().register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      viaSocial: widget.viaSocial,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final via = widget.viaSocial;
    final subtitle = via != null
        ? 'Complete your profile to finish signing in with ${via == 'google' ? 'Google' : 'Apple'}.'
        : 'Tell us a bit about yourself to personalize your commute experience.';

    return BlocConsumer<ClientAuthCubit, ClientAuthState>(
      listenWhen: (previous, current) =>
          previous.registrationStatus != current.registrationStatus,
      listener: (context, state) {
        if (state.registrationStatus == AuthSubmissionStatus.success) {
          Navigator.pushReplacementNamed(context, AuthRoutes.success);
        }
        if (state.registrationStatus == AuthSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.registrationError ?? 'Registration failed'),
            ),
          );
        }
      },
      builder: (context, authState) {
        final loading =
            authState.registrationStatus == AuthSubmissionStatus.loading;
        return AuthScaffold(
          title: 'Create your profile',
          subtitle: subtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _hasPhoto = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Photo picker — placeholder'),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _hasPhoto
                          ? const AppAvatar(initials: 'YOU', radius: 44)
                          : Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: scheme.outline.withAlpha(140),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: scheme.onSurface.withAlpha(140),
                              ),
                            ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.hXs,
              Center(
                child: Text(
                  _hasPhoto ? 'Photo added' : 'Add profile photo (optional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
              AppSpacing.hLg,
              if (_formState == _RegistrationFormState.valid && _touched)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppBadge(text: 'Ready to complete'),
                ),
              AuthLabeledField(
                label: 'Full name',
                hint: 'Ahmed Hassan',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                errorText: _nameError,
                onChanged: (_) => setState(() {}),
              ),
              AppSpacing.hMd,
              AuthLabeledField(
                label: 'Email address',
                hint: 'ahmed@company.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
                onChanged: (_) => setState(() {}),
              ),
              AppSpacing.hMd,
              AuthLabeledField(
                label: 'Phone number',
                hint: '+20 10 1234 5678',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                errorText: _phoneError,
                enabled: widget.prefilledPhone == null,
                onChanged: (_) => setState(() {}),
              ),
              AppSpacing.hLg,
              AuthPrimaryButton(
                label: 'Complete Registration',
                loading: loading,
                onPressed: loading ? null : _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}

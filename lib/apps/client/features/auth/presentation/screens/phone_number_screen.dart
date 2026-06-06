import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/widgets/app_spacing.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_labeled_field.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/widgets/mock_country_picker.dart';

enum _PhoneFieldState { empty, invalid, valid }

/// Phone number entry with country picker (UI only).
class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _phoneController = TextEditingController();
  MockCountryOption _country = kMockCountries.first;
  _PhoneFieldState _fieldState = _PhoneFieldState.empty;
  bool _touched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _errorMessage(ClientAuthState authState) {
    if (authState.phoneStatus == AuthSubmissionStatus.failure) {
      return authState.phoneError;
    }
    if (!_touched) return null;
    switch (_fieldState) {
      case _PhoneFieldState.empty:
        return 'Phone number is required';
      case _PhoneFieldState.invalid:
        return 'Enter a valid mobile number (8–11 digits)';
      case _PhoneFieldState.valid:
        return null;
    }
  }

  void _validate() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _fieldState = _PhoneFieldState.empty;
    } else if (digits.length < 8 || digits.length > 11) {
      _fieldState = _PhoneFieldState.invalid;
    } else {
      _fieldState = _PhoneFieldState.valid;
    }
  }

  Future<void> _onContinue() async {
    setState(() => _touched = true);
    _validate();
    if (_fieldState != _PhoneFieldState.valid) return;

    await context.read<ClientAuthCubit>().requestOtp(
      dialCode: _country.dialCode,
      phone: _phoneController.text.trim(),
    );
  }

  Future<void> _pickCountry() async {
    final picked = await showMockCountryPicker(context, _country);
    if (picked != null) {
      setState(() => _country = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientAuthCubit, ClientAuthState>(
      listenWhen: (previous, current) =>
          previous.phoneStatus != current.phoneStatus,
      listener: (context, state) {
        if (state.phoneStatus == AuthSubmissionStatus.success) {
          Navigator.pushNamed(
            context,
            AuthRoutes.otp,
            arguments: state.formattedPhone,
          );
        }
      },
      builder: (context, authState) {
        final loading = authState.phoneStatus == AuthSubmissionStatus.loading;
        return AuthScaffold(
          title: 'Your phone number',
          subtitle:
              'We will send a one-time code to verify your account. Standard SMS rates may apply.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mobile number',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(210),
                ),
              ),
              AppSpacing.hSm,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MockCountryPickerTile(
                    selected: _country,
                    onTap: _pickCountry,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AuthLabeledField(
                      showLabel: false,
                      hint: '10 1234 5678',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      errorText: _errorMessage(authState),
                      onChanged: (_) {
                        setState(() {
                          if (_touched) _validate();
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_fieldState == _PhoneFieldState.valid && _touched) ...[
                AppSpacing.hSm,
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Number looks good',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
              AppSpacing.hLg,
              AuthPrimaryButton(
                label: 'Continue',
                loading: loading,
                onPressed: loading ? null : _onContinue,
              ),
            ],
          ),
        );
      },
    );
  }
}

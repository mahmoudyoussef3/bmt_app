import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/app_spacing.dart';
import 'package:bmt_app/features/component/presentation/auth/auth_routes.dart';
import 'package:bmt_app/features/component/presentation/widgets/auth/auth_labeled_field.dart';
import 'package:bmt_app/features/component/presentation/widgets/auth/auth_primary_button.dart';
import 'package:bmt_app/features/component/presentation/widgets/auth/auth_scaffold.dart';
import 'package:bmt_app/features/component/presentation/widgets/auth/mock_country_picker.dart';

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
  bool _loading = false;
  bool _touched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? get _errorMessage {
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

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _loading = false);
    final formatted = '${_country.dialCode} ${_phoneController.text.trim()}';
    Navigator.pushNamed(context, AuthRoutes.otp, arguments: formatted);
  }

  Future<void> _pickCountry() async {
    final picked = await showMockCountryPicker(context, _country);
    if (picked != null) {
      setState(() => _country = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              MockCountryPickerTile(selected: _country, onTap: _pickCountry),
              const SizedBox(width: 10),
              Expanded(
                child: AuthLabeledField(
                  showLabel: false,
                  hint: '10 1234 5678',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  errorText: _errorMessage,
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
            loading: _loading,
            onPressed: _loading ? null : _onContinue,
          ),
        ],
      ),
    );
  }
}

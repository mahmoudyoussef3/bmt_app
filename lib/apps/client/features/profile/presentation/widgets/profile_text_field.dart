import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// One input in the profile editor.
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.error,
    this.keyboardType,
    this.textDirection,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? error;
  final TextInputType? keyboardType;

  /// Forced to LTR for the phone and email, which are stored and read
  /// left-to-right even when the sheet around them is Arabic.
  final TextDirection? textDirection;

  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

/// Renders a rejection from [UpdateProfileUseCase] in the rider's language.
/// The use case returns a reason, not a sentence, precisely so this mapping can
/// live here.
extension ProfileFieldErrorL10n on AppLocalizations {
  String? messageForFieldError(ProfileFieldError? error) {
    return switch (error) {
      null => null,
      ProfileFieldError.required => profile_errorRequired,
      ProfileFieldError.nameTooShort => profile_errorNameTooShort,
      ProfileFieldError.invalidPhone => profile_errorInvalidPhone,
      ProfileFieldError.invalidEmail => profile_errorInvalidEmail,
    };
  }
}

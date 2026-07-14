import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_state.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_text_field.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Edits the rider's contact details. Every save reaches Supabase — this sheet
/// does not fake one.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final ClientProfile profile;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(text: widget.profile.phone);
    _email = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().updateProfile(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final loaded = state is ProfileLoaded ? state : null;
        final errors = loaded?.fieldErrors ?? const {};

        return ClientBottomSheet(
          title: l10n.profile_editTitle,
          subtitle: l10n.profile_editBody,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileTextField(
                controller: _name,
                label: l10n.profile_fieldName,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                error: l10n.messageForFieldError(errors[ProfileField.name]),
              ),
              const SizedBox(height: AppLayout.spaceMd),
              ProfileTextField(
                controller: _phone,
                label: l10n.profile_fieldPhone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                ],
                error: l10n.messageForFieldError(errors[ProfileField.phone]),
              ),
              const SizedBox(height: AppLayout.spaceMd),
              ProfileTextField(
                controller: _email,
                label: l10n.profile_fieldEmail,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                error: l10n.messageForFieldError(errors[ProfileField.email]),
              ),
              if (loaded?.saveError != null) ...[
                const SizedBox(height: AppLayout.spaceMd),
                Text(
                  loaded!.saveError!,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.journeyRed),
                ),
              ],
              const SizedBox(height: AppLayout.spaceXl),
              ClientButton(
                label: l10n.common_save,
                isLoading: loaded?.isSaving ?? false,
                onPressed: _save,
              ),
            ],
          ),
        );
      },
    );
  }
}

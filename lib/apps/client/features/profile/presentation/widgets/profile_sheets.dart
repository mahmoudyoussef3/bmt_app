import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/appearance_sheet.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/language_sheet.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';

/// The three sheets the hub can open. Kept together so the screen stays about
/// state and navigation rather than about modal plumbing.
abstract final class ProfileSheets {
  /// Opens the editor with a clean form, and leaves it clean behind it, so
  /// reopening never starts on the previous attempt's error.
  static Future<void> edit(BuildContext context, ClientProfile profile) async {
    final cubit = context.read<ProfileCubit>();
    cubit.resetEditStatus();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The keyboard inset is read from the sheet's own context: read from the
      // screen's it would be captured once, and the sheet would sit under the
      // keyboard instead of riding above it.
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: EditProfileSheet(profile: profile),
        ),
      ),
    );

    cubit.resetEditStatus();
  }

  static Future<void> language(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LocaleCubit>(),
        child: const LanguageSheet(),
      ),
    );
  }

  static Future<void> appearance(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppearanceSheet(),
    );
  }
}

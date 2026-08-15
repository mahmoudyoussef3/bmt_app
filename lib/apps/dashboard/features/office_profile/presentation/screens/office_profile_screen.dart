import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/office_profile.dart';
import '../cubit/office_profile_cubit.dart';
import '../cubit/office_profile_state.dart';
import '../widgets/office_identity_form.dart';
import '../widgets/office_join_code_card.dart';
import '../widgets/office_marketplace_summary.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// The office's own record: the marketplace card clients browse, the reputation
/// the platform maintains, and the join code captains need to apply.
///
/// Editing is gated on [DashboardRole.admin] at the nav layer and again by the
/// `offices_operator_update` policy, so a support agent reaching this screen
/// sees it read-only rather than being bounced.
class OfficeProfileScreen extends StatelessWidget {
  const OfficeProfileScreen({super.key, required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OfficeProfileCubit, OfficeProfileState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is OfficeProfileActionSuccess) {
          messenger.showSnackBar(SnackBar(content: Text(state.message)));

          dashboardDi<DashboardAuthCubit>().refreshContext();
        } else if (state is OfficeProfileActionFailure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          OfficeProfileInitial() ||
          OfficeProfileLoading() => const DashboardLoading(),
          OfficeProfileError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<OfficeProfileCubit>().load(),
          ),
          OfficeProfileLoaded(
            :final profile,
            :final isSaving,
            :final isUploadingLogo,
          ) =>
            _Body(
              profile: profile,
              isSaving: isSaving,
              isUploadingLogo: isUploadingLogo,
              canEdit: canEdit,
            ),
          OfficeProfileActionSuccess(:final profile) ||
          OfficeProfileActionFailure(:final profile) => _Body(
            profile: profile,
            isSaving: false,
            isUploadingLogo: false,
            canEdit: canEdit,
          ),
        };
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.profile,
    required this.isSaving,
    required this.isUploadingLogo,
    required this.canEdit,
  });

  final OfficeProfile profile;
  final bool isSaving;
  final bool isUploadingLogo;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OfficeProfileCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.officeProfileActive,
          title: 'ملف المكتب',
          subtitle:
              'بيانات مكتبك كما تظهر للعملاء في دليل المكاتب، وكود انضمام الكباتن.',
          actions: [
            FilledButton.icon(
              onPressed: isSaving ? null : cubit.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.officeProfileHeader,
          summary: OfficeMarketplaceSummary(profile: profile),
        ),
        const SizedBox(height: AppSpacing.medium),
        OfficeJoinCodeCard(profile: profile),
        const SizedBox(height: AppSpacing.medium),
        OfficeIdentityForm(
          key: ValueKey(profile.updatedAt),
          profile: profile,
          isSaving: isSaving,
          isUploadingLogo: isUploadingLogo,
          canEdit: canEdit,
          onSave: cubit.save,
          onUploadLogo: (bytes, fileName) =>
              cubit.uploadLogo(bytes: bytes, fileName: fileName),
        ),
      ],
    );
  }
}

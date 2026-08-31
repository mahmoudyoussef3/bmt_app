import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/forms/forms.dart';
import 'package:bmt_app/apps/dashboard/features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/office_profile.dart';
import '../cubit/office_profile_cubit.dart';
import '../cubit/office_profile_state.dart';
import '../widgets/office_identity_form.dart';
import '../widgets/office_join_code_card.dart';
import '../widgets/office_marketplace_summary.dart';

/// The office's own record: the marketplace card clients browse, the reputation
/// the platform maintains, and the join code captains need to apply.
///
/// Three blocks, in the order an operator uses them — **نظرة عامة** (folded into
/// the header: the two status axes, the rating, and what the card is still
/// missing), **بيانات المكتب** (the editable shopfront), **كود انضمام الكباتن**
/// (the credential). Editing is gated on [DashboardRole.admin] at the nav layer
/// and again by the `offices_operator_update` policy, so a support agent
/// reaching this screen sees it read-only rather than being bounced.
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
            :final isRotatingJoinCode,
          ) =>
            _Body(
              profile: profile,
              isSaving: isSaving,
              isUploadingLogo: isUploadingLogo,
              isRotatingJoinCode: isRotatingJoinCode,
              canEdit: canEdit,
            ),
          OfficeProfileActionSuccess(:final profile) ||
          OfficeProfileActionFailure(:final profile) => _Body(
            profile: profile,
            isSaving: false,
            isUploadingLogo: false,
            isRotatingJoinCode: false,
            canEdit: canEdit,
          ),
        };
      },
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.profile,
    required this.isSaving,
    required this.isUploadingLogo,
    required this.isRotatingJoinCode,
    required this.canEdit,
  });

  final OfficeProfile profile;
  final bool isSaving;
  final bool isUploadingLogo;
  final bool isRotatingJoinCode;
  final bool canEdit;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// The one line of contact between the overview and the form under it: the
  /// checklist jumps to a field, and «تحديث» asks the form whether anything
  /// would be lost before it reloads.
  final _handle = OfficeProfileFormHandle();

  /// A reload rebuilds the form from the server's row (the form is keyed on
  /// `updatedAt`), so unsaved typing would vanish without a word. Every other
  /// editor in the console guards exactly this.
  Future<void> _refresh() async {
    final cubit = context.read<OfficeProfileCubit>();
    if (_handle.hasUnsavedChanges) {
      final discard = await confirmDiscardChanges(
        context,
        message:
            'لديك تعديلات غير محفوظة على بيانات المكتب. '
            'التحديث الآن يعيد قراءة البيانات من الخادم ويفقدها.',
      );
      if (!discard) return;
    }
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OfficeProfileCubit>();
    final profile = widget.profile;
    final missing = profile.missingMarketplaceFields;

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
              onPressed: widget.isSaving ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.officeProfileHeader,
          detailsLabel: 'نظرة عامة',
          // Opened by default when there is something to act on: an office that
          // is not on the marketplace, or a card with blanks in it, has a
          // reason to read this before touching the form.
          initiallyExpanded: !profile.isListed || missing.isNotEmpty,
          collapsedSummary: DashboardSectionSummary(
            items: [
              'التشغيل: ${profile.statusLabel}',
              'الظهور: ${profile.listingLabel}',
              if (profile.hasRatings)
                'التقييم: ${profile.rating.toStringAsFixed(1)}'
              else
                'لا تقييمات بعد',
              missing.isEmpty
                  ? 'بطاقة السوق مكتملة'
                  : 'ينقص البطاقة: ${missing.join('، ')}',
            ],
          ),
          summary: OfficeMarketplaceSummary(
            profile: profile,
            onJumpToField: widget.canEdit ? _jumpToField : null,
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        _SectionHeading(
          title: 'بيانات المكتب',
          subtitle:
              'ما تكتبه هنا هو بطاقة مكتبك في السوق. الحقول المعلّمة بـ * مطلوبة.',
        ),
        const SizedBox(height: AppSpacing.medium),
        OfficeIdentityForm(
          key: ValueKey(profile.updatedAt),
          profile: profile,
          isSaving: widget.isSaving,
          isUploadingLogo: widget.isUploadingLogo,
          canEdit: widget.canEdit,
          handle: _handle,
          onSave: cubit.save,
          onUploadLogo: (bytes, fileName) =>
              cubit.uploadLogo(bytes: bytes, fileName: fileName),
        ),
        const SizedBox(height: AppSpacing.large),
        _SectionHeading(
          title: 'كود الانضمام',
          subtitle: 'بيانات اعتماد يشاركها المكتب مع سائقيه فقط.',
        ),
        const SizedBox(height: AppSpacing.medium),
        OfficeJoinCodeCard(
          profile: profile,
          canRotate: widget.canEdit,
          isRotating: widget.isRotatingJoinCode,
          onRotate: cubit.rotateJoinCode,
          onRetry: cubit.load,
        ),
      ],
    );
  }

  Future<void> _jumpToField(String fieldId) async =>
      _handle.jumpTo?.call(fieldId);
}

/// A plain band title between the page's three blocks. Not a card: the cards
/// under it carry the chrome, and a second frame around a group of framed
/// sections is one border too many.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

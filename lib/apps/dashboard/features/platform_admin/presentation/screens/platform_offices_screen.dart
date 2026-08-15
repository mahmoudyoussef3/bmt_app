import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_filter.dart';
import '../cubit/platform_admin_cubit.dart';
import '../cubit/platform_admin_state.dart';
import '../widgets/office_onboarding_dialog.dart';
import '../widgets/onboarding_credentials_panel.dart';
import '../widgets/platform_office_card.dart';
import '../widgets/platform_office_details_panel.dart';
import '../widgets/platform_office_filters.dart';
import '../widgets/platform_overview_panel.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// Platform administration: onboard an office, and decide which offices the
/// client marketplace shows.
///
/// Reached only by an operator whose session carries `is_platform_admin`. That
/// flag is a hint for the shell — every RPC behind this screen re-checks it
/// server-side, so a forged one lands here and then fails on contact.
class PlatformOfficesScreen extends StatelessWidget {
  const PlatformOfficesScreen({super.key, this.onOpenFeatures});

  /// Hands an office over to التراخيص, which opens it on «الميزات والحدود».
  ///
  /// This screen answers "is this office real and should passengers see it";
  /// what the office is *allowed to use* is one module across, and an operator
  /// who has just looked at an office should not have to re-find it there.
  /// Null when the console cannot switch modules — a harness mounting this
  /// screen alone still renders.
  final ValueChanged<String>? onOpenFeatures;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformAdminCubit, PlatformAdminState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is PlatformAdminActionSuccess) {
          messenger.showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is PlatformAdminActionFailure) {
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
          PlatformAdminInitial() ||
          PlatformAdminLoading() => const DashboardLoading(),
          PlatformAdminError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<PlatformAdminCubit>().load(),
          ),

          PlatformAdminOnboarded(:final result) => OnboardingCredentialsPanel(
            result: result,
            onDone: () =>
                context.read<PlatformAdminCubit>().dismissOnboardingResult(),
          ),
          PlatformAdminLoaded(
            :final offices,
            :final isSubmitting,
            :final fieldErrors,
            :final filter,
            :final selection,
            :final analytics,
            :final isAnalyticsLoading,
            :final analyticsError,
          ) =>
            _Body(
              offices: offices,
              isSubmitting: isSubmitting,
              fieldErrors: fieldErrors,
              filter: filter,
              selection: selection,
              analytics: analytics,
              isAnalyticsLoading: isAnalyticsLoading,
              analyticsError: analyticsError,
              onOpenFeatures: onOpenFeatures,
            ),

          PlatformAdminActionSuccess(:final offices) => _Body(
            offices: offices,
            isSubmitting: false,
            fieldErrors: const {},
            onOpenFeatures: onOpenFeatures,
          ),
          PlatformAdminActionFailure(:final offices, :final fieldErrors) =>
            _Body(
              offices: offices,
              isSubmitting: false,
              fieldErrors: fieldErrors,
              onOpenFeatures: onOpenFeatures,
            ),
        };
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.offices,
    required this.isSubmitting,
    required this.fieldErrors,
    this.filter = const PlatformOfficeFilter(),
    this.selection,
    this.analytics,
    this.isAnalyticsLoading = false,
    this.analyticsError,
    this.onOpenFeatures,
  });

  final List<PlatformOffice> offices;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final PlatformOfficeFilter filter;
  final PlatformOfficeSelection? selection;
  final PlatformAnalytics? analytics;
  final bool isAnalyticsLoading;
  final String? analyticsError;
  final ValueChanged<String>? onOpenFeatures;

  @override
  Widget build(BuildContext context) {
    final master = _OfficeList(
      offices: offices,
      isSubmitting: isSubmitting,
      fieldErrors: fieldErrors,
      filter: filter,
      selectedId: selection?.officeId,
      analytics: analytics,
      isAnalyticsLoading: isAnalyticsLoading,
      analyticsError: analyticsError,
      onOpenFeatures: onOpenFeatures,
    );

    final open = selection;
    if (open == null) return master;

    final office = offices.where((o) => o.id == open.officeId).firstOrNull;

    return MasterDetailLayout(
      master: master,
      masterFlex: 3,
      detailFlex: 4,
      detail: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: PlatformOfficeDetailsPanel(
          officeName: office?.name ?? 'المكتب',
          details: open.details,
          onOpenFeatures: onOpenFeatures == null
              ? null
              : () => onOpenFeatures!(open.officeId),
          metrics: analytics?.metricsFor(open.officeId),
          windowDays: analytics?.windowDays ?? 30,
          isLoading: open.isLoading,
          error: open.error,
          isBusy: isSubmitting,
          onClose: context.read<PlatformAdminCubit>().closeDetails,
          onRetry: () =>
              context.read<PlatformAdminCubit>().openDetails(open.officeId),
          onSetListing: (status) => context
              .read<PlatformAdminCubit>()
              .setListing(open.officeId, status),
          onSetStatus: (status) => context.read<PlatformAdminCubit>().setStatus(
            open.officeId,
            status,
          ),
        ),
      ),
    );
  }
}

class _OfficeList extends StatelessWidget {
  const _OfficeList({
    required this.offices,
    required this.isSubmitting,
    required this.fieldErrors,
    required this.filter,
    required this.selectedId,
    required this.analytics,
    required this.isAnalyticsLoading,
    required this.analyticsError,
    required this.onOpenFeatures,
  });

  final List<PlatformOffice> offices;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final PlatformOfficeFilter filter;
  final String? selectedId;
  final PlatformAnalytics? analytics;
  final bool isAnalyticsLoading;
  final String? analyticsError;
  final ValueChanged<String>? onOpenFeatures;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformAdminCubit>();
    final metrics = analytics?.offices ?? const {};
    final visible = filter.apply(offices, metrics: metrics);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.platformOfficesActive,
          title: 'مكاتب المنصة',
          subtitle:
              'أداء كل مكتب على المنصة، وإنشاء مكتب نقل جديد بحساب مسؤوله '
              'الأول، والتحكم في ظهوره داخل سوق العملاء.',
          actions: [
            FilledButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () => showOfficeOnboardingDialog(context),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('مكتب جديد'),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : cubit.load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تحديث'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),

        PlatformOverviewPanel(
          analytics: analytics,
          offices: offices,
          isLoading: isAnalyticsLoading,
          error: analyticsError,
          onWindowChanged: cubit.setWindow,
          onRetry: cubit.retryAnalytics,
          onOpenOffice: cubit.openDetails,
        ),
        const SizedBox(height: AppSpacing.medium),
        PlatformOfficeFilters(
          filter: filter,
          resultCount: visible.length,
          totalCount: offices.length,
          hasMetrics: metrics.isNotEmpty,
          onSearch: cubit.search,
          onStatus: cubit.filterByStatus,
          onListingStatus: cubit.filterByListingStatus,
          onActivity: cubit.filterByActivity,
          onSort: cubit.sortBy,
          onClear: cubit.clearFilters,
        ),
        const SizedBox(height: AppSpacing.medium),
        // No «المكاتب المسجلة (N)» heading: the filter bar directly above already
        // reports the count, and repeating it was a line of chrome saying what
        // the line above it just said.
        if (offices.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.platformOffices,
              title: 'لا توجد مكاتب بعد',
              message:
                  'أنشئ أول مكتب نقل بحساب مسؤوله الأول، ثم عيّن له باقة من '
                  'شاشة التراخيص.',
              action: FilledButton.icon(
                onPressed: () => showOfficeOnboardingDialog(context),
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: const Text('مكتب جديد'),
              ),
            ),
          )
        else if (visible.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.platformOffices,
              title: 'لا مكتب يطابق التصفية',
              message: 'جرّب اسمًا آخر أو أزل عوامل التصفية الحالية.',
              action: TextButton.icon(
                onPressed: cubit.clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('مسح عوامل التصفية'),
              ),
            ),
          )
        else
          for (final office in visible) ...[
            PlatformOfficeCard(
              office: office,
              metrics: metrics[office.id],
              isBusy: isSubmitting,
              isSelected: office.id == selectedId,
              onOpen: () => cubit.openDetails(office.id),
              onOpenFeatures: onOpenFeatures == null
                  ? null
                  : () => onOpenFeatures!(office.id),
              onSetListing: (status) => cubit.setListing(office.id, status),
              onSetStatus: (status) => cubit.setStatus(office.id, status),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
      ],
    );
  }
}

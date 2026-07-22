import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_filter.dart';
import '../cubit/platform_admin_cubit.dart';
import '../cubit/platform_admin_state.dart';
import '../widgets/office_onboarding_form.dart';
import '../widgets/onboarding_credentials_panel.dart';
import '../widgets/platform_office_card.dart';
import '../widgets/platform_office_details_panel.dart';
import '../widgets/platform_office_filters.dart';
import '../widgets/platform_overview_panel.dart';

/// Platform administration: onboard an office, and decide which offices the
/// client marketplace shows.
///
/// Reached only by an operator whose session carries `is_platform_admin`. That
/// flag is a hint for the shell — every RPC behind this screen re-checks it
/// server-side, so a forged one lands here and then fails on contact.
class PlatformOfficesScreen extends StatelessWidget {
  const PlatformOfficesScreen({super.key});

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
          // The one-time credential reveal takes over the screen: it is the only
          // copy of the password that will ever exist, so it must not be
          // reachable-then-lost behind a scroll position or a rebuild.
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
            ),
          // The transient action states carry the office list but no filter of
          // their own; they are followed immediately by a `PlatformAdminLoaded`
          // that does. Rendering the unfiltered list for that one frame would
          // flash every office back onto a screen the operator had narrowed, so
          // these keep showing the list they were given without re-filtering it.
          PlatformAdminActionSuccess(:final offices) => _Body(
            offices: offices,
            isSubmitting: false,
            fieldErrors: const {},
          ),
          PlatformAdminActionFailure(:final offices, :final fieldErrors) =>
            _Body(
              offices: offices,
              isSubmitting: false,
              fieldErrors: fieldErrors,
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
  });

  final List<PlatformOffice> offices;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final PlatformOfficeFilter filter;
  final PlatformOfficeSelection? selection;
  final PlatformAnalytics? analytics;
  final bool isAnalyticsLoading;
  final String? analyticsError;

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
    );

    final open = selection;
    if (open == null) return master;

    // The office the panel is about, taken from the list so the panel has a name
    // to show before its own fetch resolves.
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
  });

  final List<PlatformOffice> offices;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final PlatformOfficeFilter filter;
  final String? selectedId;
  final PlatformAnalytics? analytics;
  final bool isAnalyticsLoading;
  final String? analyticsError;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformAdminCubit>();
    final metrics = analytics?.offices ?? const {};
    final visible = filter.apply(offices, metrics: metrics);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: Icons.apartment_outlined,
          title: 'مكاتب المنصة',
          subtitle:
              'أداء كل مكتب على المنصة، وإنشاء مكتب نقل جديد بحساب مسؤوله '
              'الأول، والتحكم في ظهوره داخل سوق العملاء.',
          actions: [
            FilledButton.icon(
              onPressed: isSubmitting ? null : cubit.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        // Describes the platform, never the current search: the header would
        // stop being an overview if it changed with every keystroke.
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
        OfficeOnboardingForm(
          isSubmitting: isSubmitting,
          fieldErrors: fieldErrors,
          onSubmit: cubit.onboard,
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
        Text(
          'المكاتب المسجلة (${visible.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.small),
        if (offices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.large),
            child: Text('لا توجد مكاتب بعد.'),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              children: [
                const Text('لا توجد مكاتب مطابقة لعوامل التصفية الحالية.'),
                const SizedBox(height: AppSpacing.small),
                TextButton.icon(
                  onPressed: cubit.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('مسح عوامل التصفية'),
                ),
              ],
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
              onSetListing: (status) => cubit.setListing(office.id, status),
              onSetStatus: (status) => cubit.setStatus(office.id, status),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../../domain/entities/captain_request.dart';
import '../cubit/captain_requests_cubit.dart';
import '../cubit/captain_requests_state.dart';
import '../widgets/captain_request_approve_flow.dart';
import '../widgets/captain_request_reject_dialog.dart';
import '../widgets/captain_requests_board.dart';
import '../widgets/captain_requests_format.dart';
import '../widgets/captain_requests_summary.dart';
import '../widgets/captain_requests_toolbar.dart';

/// طلبات الكباتن — the joining queue: decide who drives for this office.
///
/// Mounted inside the dashboard shell, which already supplies the page chrome
/// (title bar, navigation, RTL) — so this screen contributes only its own
/// content, exactly like every other module.
///
/// ## One shape for every list module
///
/// Header with its KPI strip → the shared filter bar (queue strip, pinned
/// search and ordering, the rest behind one fold) → the results header → the
/// rows. الشكاوى next door is composed the same way, and so are the three
/// المبيعات modules: the section an operator is in should never change what the
/// controls are or where they live. This screen used to be a bare header with a
/// two-segment toggle over an unpaginated, unsearchable `ListView` of cards,
/// which is why الأسطول section read as a different console.
///
/// ## Why there is no «دعوة سائق» button
///
/// The design's header carries one, but this office cannot invite anyone:
/// captains apply from the captain app themselves, and the office's join code
/// lives on ملف المكتب. A primary action that opens nothing is worse than the
/// honest absence of one — the empty state says where requests come from
/// instead.
class CaptainRequestsScreen extends StatelessWidget {
  const CaptainRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CaptainRequestsCubit, CaptainRequestsState>(
      listenWhen: (p, c) => c is CaptainRequestsLoaded && c.actionError != null,
      listener: (context, state) {
        if (state is CaptainRequestsLoaded && state.actionError != null) {
          AppSnackbar.error(context, state.actionError!);
        }
      },
      builder: (context, state) => switch (state) {
        CaptainRequestsLoading() => const DashboardLoading(rows: 6),
        CaptainRequestsError(:final message) => DashboardErrorState(
          title: 'تعذر تحميل طلبات الكباتن',
          message: message,
          onRetry: () => context.read<CaptainRequestsCubit>().load(),
        ),
        CaptainRequestsLoaded() => _LoadedView(state: state),
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final CaptainRequestsLoaded state;

  Future<void> _approve(BuildContext context, CaptainRequest r) =>
      CaptainRequestApproveFlow.start(
        context,
        context.read<CaptainRequestsCubit>(),
        r,
      );

  Future<void> _reject(BuildContext context, CaptainRequest r) async {
    final cubit = context.read<CaptainRequestsCubit>();
    final reason = await CaptainRequestRejectDialog.show(context, r.fullName);
    if (reason == null) return;
    await cubit.reject(requestId: r.id, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptainRequestsCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.captainRequestsActive,
          title: 'طلبات الكباتن',
          subtitle: 'طلبات الانضمام بانتظار قرارك — اقبلها أو ارفضها مع السبب.',
          actions: [
            FilledButton.tonalIcon(
              onPressed: cubit.load,
              icon: const Icon(DashboardIcons.refresh),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.captainRequestsHeader,
          // Open, like every other list module's header: the four counts *are*
          // what this screen is opened to read, and three of them are the
          // shortcut to the queue behind them.
          initiallyExpanded: true,
          collapsedSummary: DashboardSectionSummary(
            items: [
              'بانتظار القرار ${CaptainRequestsFormat.count(state.pendingCount)}',
              'مقبولون ${CaptainRequestsFormat.count(state.approvedCount)}',
              'مرفوضون ${CaptainRequestsFormat.count(state.rejectedCount)}',
            ],
          ),
          summary: CaptainRequestsSummary(
            state: state,
            onOpenQueue: cubit.switchTab,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        CaptainRequestsToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        CaptainRequestsBoard(
          state: state,
          onApprove: (r) => _approve(context, r),
          onReject: (r) => _reject(context, r),
          onSort: cubit.setSort,
          onClearFilters: cubit.clearFilters,
        ),
      ],
    );
  }
}

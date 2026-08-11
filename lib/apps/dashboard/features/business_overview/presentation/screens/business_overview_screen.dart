import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_attention.dart';
import '../../domain/entities/business_overview.dart';
import '../cubit/business_overview_cubit.dart';
import '../cubit/business_overview_state.dart';
import '../widgets/business_attention_section.dart';
import '../widgets/business_health_section.dart';
import '../widgets/business_overview_header.dart';
import '../widgets/customer_snapshot_section.dart';
import '../widgets/financial_snapshot_section.dart';
import '../widgets/operational_snapshot_section.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/smart_insights_section.dart';
import '../widgets/today_kpis_section.dart';

/// The executive tab: how the business is doing, and what needs the owner.
///
/// ## Reading order
///
/// The eight sections are stacked in the order the questions get asked, and
/// that order is the design:
///
/// 1. **مؤشرات اليوم** — what happened today, with movement and shape.
/// 2. **صحة النشاط** — is anything off target, graded against stated rules.
/// 3. **قراءات وتوصيات** — what those numbers mean, in sentences.
/// 4. **يحتاج قراراً منك** — the queues, before the owner gets comfortable.
/// 5. **الملخص المالي** — money, at a summary height.
/// 6. **الملخص التشغيلي** — today's operations, at a summary height.
/// 7. **قاعدة العملاء** — who is buying, and whether they come back.
/// 8. **إجراءات سريعة** — what to do about any of it.
///
/// Every one folds independently and remembers its state for the session, so an
/// owner who reads money first can collapse the rest once and find that layout
/// waiting for them tomorrow.
///
/// ## What this screen is not
///
/// Not an admin surface. Nothing here writes: every row, tile and button leads
/// to the module that owns the decision. That is the line between this and the
/// operator's console on `/`, and it is what keeps the page readable in the
/// thirty seconds it is designed for.
class BusinessOverviewScreen extends StatelessWidget {
  const BusinessOverviewScreen({
    super.key,
    required this.office,
    required this.canOpenRoute,
    this.entitlements,
    this.onOpenModule,
    this.onCreateTrip,
  });

  final OfficeContext office;

  /// The shell's `role ∧ entitlement` gate. Quick actions and drill-ins the
  /// operator cannot use are dropped rather than shown disabled.
  final bool Function(String route) canOpenRoute;

  /// The resolved licence, read live rather than from the loaded snapshot:
  /// entitlements change when a contract changes, not when this page refreshes.
  final EntitlementContext? entitlements;

  final ValueChanged<String>? onOpenModule;

  /// Opens the trip planner. Owned by the shell, which owns navigation.
  final VoidCallback? onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessOverviewCubit, BusinessOverviewState>(
      builder: (context, state) {
        return switch (state) {
          BusinessOverviewLoading() => const DashboardLoading(),
          BusinessOverviewError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<BusinessOverviewCubit>().load(),
          ),
          BusinessOverviewLoaded(:final overview, :final isRefreshing) =>
            _LoadedView(
              office: office,
              overview: overview,
              isRefreshing: isRefreshing,
              entitlements: entitlements,
              canOpenRoute: canOpenRoute,
              onOpenModule: onOpenModule ?? (_) {},
              onCreateTrip: onCreateTrip,
            ),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.office,
    required this.overview,
    required this.isRefreshing,
    required this.canOpenRoute,
    required this.onOpenModule,
    this.entitlements,
    this.onCreateTrip,
  });

  final OfficeContext office;
  final BusinessOverview overview;
  final bool isRefreshing;
  final bool Function(String route) canOpenRoute;
  final ValueChanged<String> onOpenModule;
  final EntitlementContext? entitlements;
  final VoidCallback? onCreateTrip;

  @override
  Widget build(BuildContext context) {
    
    final attention = [
      ...overview.attentionItems,
      ...licenseLimitAttention(entitlements),
    ]..sort((a, b) {
      final bySeverity = b.kind.severity.index.compareTo(a.kind.severity.index);
      return bySeverity != 0 ? bySeverity : b.count.compareTo(a.count);
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        BusinessOverviewHeader(
          office: office,
          overview: overview,
          isRefreshing: isRefreshing,
          onRefresh: () => context.read<BusinessOverviewCubit>().refresh(),
        ),
        if (overview.unavailable.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          UnavailableSourcesNotice(sources: overview.unavailable),
        ],
        const SizedBox(height: AppSpacing.medium),
        TodayKpisSection(overview: overview, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        BusinessHealthSection(overview: overview, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        SmartInsightsSection(
          insights: overview.insights,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        BusinessAttentionSection(
          items: attention,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        FinancialSnapshotSection(
          overview: overview,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        OperationalSnapshotSection(
          overview: overview,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        CustomerSnapshotSection(
          overview: overview,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        QuickActionsSection(
          onOpenModule: onOpenModule,
          canOpen: canOpenRoute,
          onCreateTrip: onCreateTrip,
        ),
      ],
    );
  }
}

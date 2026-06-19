import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/owner_overview.dart';
import '../cubit/owner_overview_cubit.dart';
import '../cubit/owner_overview_state.dart';
import '../widgets/owner_overview_charts.dart';

class OwnerOverviewScreen extends StatelessWidget {
  const OwnerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OwnerOverviewCubit, OwnerOverviewState>(
      builder: (context, state) {
        return switch (state) {
          OwnerOverviewLoading() => const DashboardLoading(),
          OwnerOverviewError(:final message) => DashboardErrorState(
              message: message,
              onRetry: () => context.read<OwnerOverviewCubit>().load(),
            ),
          OwnerOverviewLoaded(:final overview) => _LoadedView(overview: overview),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final OwnerOverview overview;
  const _LoadedView({required this.overview});

  @override
  Widget build(BuildContext context) {
    String money(double v) => '${v.toStringAsFixed(0)} ج.م';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: Icons.insights_rounded,
          title: 'نظرة المالك على الإيرادات',
          subtitle: 'ملخص تنفيذي للإيرادات والعملاء والاشتراكات من بيانات حقيقية.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.read<OwnerOverviewCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardKpiGrid(
          children: [
            DashboardKpiCard(
              label: 'إجمالي الإيرادات',
              value: money(overview.totalRevenue),
              icon: Icons.payments_rounded,
              color: const Color(0xFF2563EB),
            ),
            DashboardKpiCard(
              label: 'إيراد الاشتراكات',
              value: money(overview.subscriptionsRevenue),
              icon: Icons.workspace_premium_rounded,
              color: const Color(0xFF8B5CF6),
            ),
            DashboardKpiCard(
              label: 'إيراد الحجوزات (الشهر)',
              value: money(overview.bookingsRevenueMonth),
              icon: Icons.event_seat_rounded,
              color: const Color(0xFF16A34A),
            ),
            DashboardKpiCard(
              label: 'إيراد اليوم',
              value: money(overview.bookingsRevenueToday),
              icon: Icons.today_rounded,
            ),
            DashboardKpiCard(
              label: 'العملاء النشطون',
              value: '${overview.activeClients}',
              icon: Icons.group_rounded,
              color: const Color(0xFF16A34A),
            ),
            DashboardKpiCard(
              label: 'اشتراكات منتهية',
              value: '${overview.expiredClients}',
              icon: Icons.history_toggle_off_rounded,
              color: const Color(0xFF64748B),
            ),
            DashboardKpiCard(
              label: 'اشتراكات ملغاة',
              value: '${overview.cancelledClients}',
              icon: Icons.cancel_rounded,
              color: const Color(0xFFDC2626),
            ),
            DashboardKpiCard(
              label: 'إجمالي التجديدات',
              value: '${overview.renewalsTotal}',
              icon: Icons.autorenew_rounded,
              color: const Color(0xFF0EA5E9),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        OwnerOverviewCharts(overview: overview),
        const SizedBox(height: AppSpacing.medium),
        const _SaasGapNote(),
      ],
    );
  }
}

/// Honest disclosure: true multi-tenant SaaS metrics need backend that does
/// not exist yet, so they are not shown rather than fabricated.
class _SaasGapNote extends StatelessWidget {
  const _SaasGapNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'مقاييس SaaS متعددة المستأجرين (الشركات، MRR، معدل التسرب) تتطلب '
              'بنية خلفية غير متوفرة حاليًا، لذا لا تُعرض بدلاً من تقديم أرقام غير حقيقية.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

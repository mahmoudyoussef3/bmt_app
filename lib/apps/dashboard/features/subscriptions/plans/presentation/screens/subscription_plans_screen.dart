import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/subscription_plan.dart';
import '../cubit/subscription_plans_cubit.dart';
import '../cubit/subscription_plans_state.dart';
import '../widgets/plan_card.dart';
import '../widgets/plan_form_sheet.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import '../../../presentation/widgets/subscription_formatting.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionPlansCubit, SubscriptionPlansState>(
      listenWhen: (p, c) =>
          c is SubscriptionPlansLoaded && c.actionMessage != null,
      listener: (context, state) {
        if (state is SubscriptionPlansLoaded && state.actionMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
        }
      },
      builder: (context, state) {
        return switch (state) {
          SubscriptionPlansLoading() => const DashboardLoading(),
          SubscriptionPlansError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<SubscriptionPlansCubit>().load(),
          ),
          SubscriptionPlansLoaded() => _LoadedView(state: state),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final SubscriptionPlansLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final cubit = context.read<SubscriptionPlansCubit>();
    final active = state.plans
        .where((p) => p.status == PlanStatus.active)
        .length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.subscriptionsActive,
          title: 'إدارة باقات الاشتراك',
          subtitle: 'أنشئ وعدّل وفعّل أو أوقف باقات الاشتراك.',
          actions: [
            FilledButton.icon(
              onPressed: () => _create(context, cubit),
              icon: const Icon(Icons.add_rounded),
              label: const Text('باقة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardKpiGrid(
          children: [
            DashboardKpiCard(
              label: 'إجمالي الباقات',
              value: arabicNumber(state.plans.length),
              icon: Icons.inventory_2_outlined,
            ),
            DashboardKpiCard(
              label: 'الباقات النشطة',
              value: arabicNumber(active),
              icon: Icons.check_circle_outline,
              color: palette.positive,
            ),
            DashboardKpiCard(
              label: 'الإيراد الشهري المتكرر التقديري',
              value: subscriptionMoney(state.monthlyRecurringRevenue),
              icon: Icons.trending_up_rounded,
              color: palette.active,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        if (state.plans.isEmpty)
          const AppCard(
            child: Center(child: Text('لا توجد باقات بعد. أنشئ باقة جديدة.')),
          )
        else
          ...state.plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: PlanCard(
                plan: plan,
                onEdit: () => _edit(context, cubit, plan),
                onToggleStatus: () => cubit.setStatus(
                  plan.id,
                  plan.status == PlanStatus.active
                      ? PlanStatus.paused
                      : PlanStatus.active,
                ),
                onDelete: () => _confirmDelete(context, cubit, plan),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _create(
    BuildContext context,
    SubscriptionPlansCubit cubit,
  ) async {
    final plan = await showPlanForm(context);
    if (plan != null) cubit.create(plan);
  }

  Future<void> _edit(
    BuildContext context,
    SubscriptionPlansCubit cubit,
    SubscriptionPlan plan,
  ) async {
    final edited = await showPlanForm(context, existing: plan);
    if (edited != null) cubit.update(edited);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SubscriptionPlansCubit cubit,
    SubscriptionPlan plan,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الباقة'),
        content: Text('هل تريد حذف "${plan.title}" نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.delete(plan.id);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/entitlements/licensing_dialogs.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/dashboard_state_views.dart';
import '../../../platform_licensing/presentation/widgets/licensing_widgets.dart';
import '../cubit/office_billing_cubit.dart';

/// الباقة والفوترة — the office's own commercial screen. Owner only.
///
/// The office **cannot change its own plan here** (§17.2): a checkout without a
/// payment gateway would be a lie, and a plan change has proration implications
/// that need a real billing engine. So the call to action is contact, not
/// purchase — and saying that plainly is better than a disabled "upgrade"
/// button that teaches the owner the console is broken.
class OfficeBillingScreen extends StatelessWidget {
  const OfficeBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfficeBillingCubit, OfficeBillingState>(
      builder: (context, state) => switch (state) {
        OfficeBillingLoading() => const DashboardLoading(),
        OfficeBillingError(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<OfficeBillingCubit>().load(),
        ),
        OfficeBillingLoaded() => _Loaded(state: state),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final OfficeBillingLoaded state;

  @override
  Widget build(BuildContext context) {
    final license = state.license;
    final limits = state.entitlements.limits;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LicenseBanner(license: license),
          DashboardModuleHeader(
            icon: DashboardIcons.officeBilling,
            title: 'الباقة والفوترة',
            subtitle: 'باقتك الحالية، وما تشمله، وفواتيرك.',
            sectionId: DashboardSectionIds.officeBillingHeader,
            summary: DashboardKpiGrid(
              children: [
                DashboardKpiCard(
                  label: 'الباقة',
                  value: license.planNameAr.isEmpty ? '—' : license.planNameAr,
                  icon: DashboardIcons.plans,
                  detail: license.statusLabelAr,
                ),
                DashboardKpiCard(
                  label: 'التجديد',
                  value: licensingDate(license.periodEnd),
                  icon: DashboardIcons.time,
                  detail: license.autoRenew
                      ? 'تجديد تلقائي'
                      : 'بدون تجديد تلقائي',
                ),
                DashboardKpiCard(
                  label: 'القيمة',
                  value: licensingMoney(license.price, license.currency),
                  icon: DashboardIcons.payments,
                  detail: switch (license.billingCycle) {
                    'yearly' => 'سنويًا',
                    'monthly' => 'شهريًا',
                    'custom' => 'عقد مخصص',
                    'free' => 'مجانية',
                    _ => '',
                  },
                ),
                if (license.isTrialing)
                  DashboardKpiCard(
                    label: 'باقٍ من التجربة',
                    value: '${license.trialDaysLeft ?? 0} يوم',
                    icon: DashboardIcons.attention,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (limits.isNotEmpty) ...[
            DashboardPanel(
              sectionId: DashboardSectionIds.officeBillingUsage,
              icon: DashboardIcons.usage,
              title: 'الاستخدام',
              subtitle: 'ما استهلكته من حدود باقتك.',
              child: Column(
                children: [
                  for (final limit in limits)
                    UsageBar(
                      label: limit.nameAr,
                      used: limit.used ?? 0,
                      limit: limit.limit,
                      unit: limit.unitAr,
                    ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'الحد يمنع الإضافة الجديدة فقط. لا يُحذف ولا يُعطَّل أي عنصر '
                    'قائم عند تغيير الباقة.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
          ],
          _IncludedFeatures(state: state),
          const SizedBox(height: AppSpacing.medium),
          _Invoices(state: state),
        ],
      ),
    );
  }
}

class _IncludedFeatures extends StatelessWidget {
  const _IncludedFeatures({required this.state});

  final OfficeBillingLoaded state;

  static const _categories = <String, String>{
    'operations': 'التشغيل',
    'fleet': 'الأسطول',
    'sales': 'المبيعات والعملاء',
    'finance': 'المالية',
    'insight': 'التقارير والتحليل',
    'engagement': 'التواصل والدعم',
    'platform': 'المنصة والتوسع',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DashboardPanel(
      sectionId: DashboardSectionIds.officeBillingPlan,
      icon: DashboardIcons.featureCatalog,
      title: 'ما تشمله باقتك',
      subtitle: 'المتاح، وما يمكن إضافته بترقية.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in _categories.entries)
            () {
              final features = state
                  .included(category.key)
                  .where((f) => f.valueType != 'limit')
                  .toList();
              if (features.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.value,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.xSmall,
                      children: [
                        for (final feature in features)
                          _FeatureChip(feature: feature, scheme: scheme),
                      ],
                    ),
                  ],
                ),
              );
            }(),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: DashboardColors.well(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.border(context)),
            ),
            child: Row(
              children: [
                Icon(DashboardIcons.locked, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    'لترقية الباقة أو رفع أي حد، تواصل مع إدارة المنصة. '
                    'تغيير الباقة لا يتم ذاتيًا في هذا الإصدار.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.feature, required this.scheme});

  final ResolvedFeature feature;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final on = feature.isOn;

    final blocked = feature.blockedBy != null;

    final color = on
        ? scheme.secondary
        : (blocked ? scheme.tertiary : scheme.outline);

    return Tooltip(
      message: blocked
          ? 'تتطلب تفعيل ميزة أخرى أولًا'
          : (on ? 'متاحة في باقتك' : 'غير متاحة في باقتك الحالية'),
      child: StatusChip(
        label: feature.valueType == 'enum'
            ? '${feature.nameAr}: ${feature.value}'
            : feature.nameAr,
        color: color.withAlpha(on ? 24 : 14),
        textColor: color,
      ),
    );
  }
}

class _Invoices extends StatelessWidget {
  const _Invoices({required this.state});

  final OfficeBillingLoaded state;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      sectionId: DashboardSectionIds.officeBillingInvoices,
      icon: DashboardIcons.billing,
      title: 'الفواتير',
      child: state.invoices.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.billing,
              title: 'لا توجد فواتير',
              message: 'لم تصدر أي فاتورة اشتراك لهذا المكتب بعد.',
            )
          : Column(
              children: [
                for (final invoice in state.invoices)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(invoice.invoiceNumber),
                    subtitle: Text(
                      '${licensingDate(invoice.periodStart)} → '
                      '${licensingDate(invoice.periodEnd)}'
                      '${invoice.dueAt == null ? '' : ' · استحقاق ${licensingDate(invoice.dueAt)}'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(licensingMoney(invoice.total, invoice.currency)),
                        const SizedBox(width: AppSpacing.small),
                        StatusChip(label: invoice.statusLabelAr),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

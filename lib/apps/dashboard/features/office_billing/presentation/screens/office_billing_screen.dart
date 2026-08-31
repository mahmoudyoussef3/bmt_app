import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_collapsible_section.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/dashboard_state_views.dart';
import '../cubit/office_billing_cubit.dart';
import '../models/office_license_view.dart';
import '../widgets/office_features_panel.dart';
import '../widgets/office_invoices_panel.dart';
import '../widgets/office_limits_panel.dart';
import '../widgets/office_subscription_card.dart';
import '../widgets/office_upgrade_request_dialog.dart';

/// الباقة والفوترة — the office's own commercial screen. Owner only.
///
/// Four blocks, in the order the questions arrive: **حالة الاشتراك** (what am I
/// on, what does it cost, what happens next), **الاستخدام والحدود** (what will
/// stop me, and when), **ما تشمله باقتك** (what I have, and why I don't have the
/// rest), **الفواتير** (what I have been charged).
///
/// The office **cannot change its own plan here** (§17.2): a checkout without a
/// payment gateway would be a lie, and a plan change has proration implications
/// that need a real billing engine. So the call to action is contact, not
/// purchase — but contact is now a prepared request rather than a sentence in a
/// grey box.
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
        OfficeBillingLoaded() => OfficeBillingView(
          state: state,
          onRefresh: () => context.read<OfficeBillingCubit>().load(),
          onRetryInvoices: () =>
              context.read<OfficeBillingCubit>().reloadInvoices(),
        ),
      },
    );
  }
}

/// The loaded screen, separated from its cubit so a test can pump it against a
/// hand-built [OfficeBillingLoaded] — the cubit needs a live Supabase client to
/// exist, and none of what this draws depends on that.
class OfficeBillingView extends StatelessWidget {
  const OfficeBillingView({
    super.key,
    required this.state,
    this.onRefresh,
    this.onRetryInvoices,
  });

  final OfficeBillingLoaded state;
  final VoidCallback? onRefresh;
  final VoidCallback? onRetryInvoices;

  @override
  Widget build(BuildContext context) {
    final license = state.license;
    final view = LicenseStatusView.of(license);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.officeBilling,
          title: 'الباقة والفوترة',
          subtitle: 'باقتك الحالية، وما تشمله من ميزات وحدود، وفواتيرك.',
          actions: [
            if (onRefresh != null)
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(DashboardIcons.refresh, size: 18),
                label: const Text('تحديث'),
              ),
          ],
        ),

        // Not folded, and not a KPI strip: the plan, its state and its next date
        // are the reason the screen was opened, and they used to sit behind the
        // header's «الملخص» toggle.
        OfficeSubscriptionCard(
          license: license,
          onContact: () => _requestUpgrade(context),
        ),
        const SizedBox(height: AppSpacing.large),

        DashboardPanel(
          sectionId: DashboardSectionIds.officeBillingUsage,
          icon: DashboardIcons.usage,
          title: 'الاستخدام والحدود',
          subtitle: 'ما استهلكته من حدود باقتك، وما يمنعه تجاوزها.',
          collapsedSummary: DashboardSectionSummary(items: _usageSummary()),
          child: OfficeLimitsPanel(
            capped: state.cappedMeters,
            uncapped: state.uncappedMeters,
            closed: state.closedMeters,
            overLimit: state.overLimitMeters,
            nearLimit: state.nearLimitMeters,
            isEnforcing: state.entitlements.isEnforcing,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),

        DashboardPanel(
          sectionId: DashboardSectionIds.officeBillingPlan,
          icon: DashboardIcons.featureCatalog,
          title: 'ما تشمله باقتك',
          subtitle: 'المتاح، وسبب عدم إتاحة الباقي.',
          child: OfficeFeaturesPanel(
            groups: _featureGroups(),
            nameOfFeature: (key) =>
                state.entitlements.feature(key)?.nameAr ?? key,
            onContact: () => _requestUpgrade(context),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),

        DashboardPanel(
          sectionId: DashboardSectionIds.officeBillingInvoices,
          icon: DashboardIcons.billing,
          title: 'الفواتير',
          subtitle: 'ما صدر لمكتبك من فواتير اشتراك.',
          collapsedSummary: DashboardSectionSummary(
            items: [
              if (state.invoicesError != null)
                'تعذر تحميل الفواتير'
              else
                '${state.invoices.length} فاتورة',
            ],
          ),
          child: OfficeInvoicesPanel(
            invoices: state.invoices,
            error: state.invoicesError,
            isLoading: state.isLoadingInvoices,
            onRetry: onRetryInvoices ?? () {},
          ),
        ),

        if (view.isRestricted) ...[
          const SizedBox(height: AppSpacing.medium),
          const _ReadOnlyFooter(),
        ],
      ],
    );
  }

  /// The folded usage section still has to answer "do I need to open this?".
  List<String> _usageSummary() {
    final over = state.overLimitMeters;
    final near = state.nearLimitMeters;
    return [
      if (over.isNotEmpty) 'تجاوزت ${over.length} حدًّا',
      if (over.isEmpty && near.isNotEmpty) 'اقتربت من ${near.length} حد',
      '${state.cappedMeters.length} حد محدود',
      if (state.uncappedMeters.isNotEmpty)
        '${state.uncappedMeters.length} بلا حدود',
    ];
  }

  Map<String, List<ResolvedFeature>> _featureGroups() {
    final groups = <String, List<ResolvedFeature>>{};
    for (final entry in OfficeFeaturesPanel.categories.entries) {
      final features = state.included(entry.key);
      if (features.isNotEmpty) groups[entry.value] = features;
    }
    return groups;
  }

  void _requestUpgrade(BuildContext context) {
    showOfficeUpgradeRequest(
      context,
      license: state.license,
      officeName: state.officeName,
      pressuredMeters: [...state.overLimitMeters, ...state.nearLimitMeters],
    );
  }
}

/// Repeats the one thing a held office most needs to know, at the end of the
/// screen it will have scrolled through looking for it.
class _ReadOnlyFooter extends StatelessWidget {
  const _ReadOnlyFooter();

  @override
  Widget build(BuildContext context) {
    final status = context.status(AppStatusTone.error);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(DashboardIcons.locked, size: 16, color: status.accent),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            'وضع القراءة فقط لا يحذف شيئًا: بياناتك وتذاكرك المُباعة ورحلاتك '
            'الجارية كما هي، ويعود الإنشاء فور عودة الترخيص.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

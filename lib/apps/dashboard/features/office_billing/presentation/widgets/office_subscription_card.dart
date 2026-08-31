import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_status_chip.dart';
import '../../../platform_licensing/presentation/widgets/licensing_widgets.dart';
import '../models/office_license_view.dart';

/// حالة الاشتراك — the answer to "what am I on, what does it cost, and what
/// happens next", in one block at the top of the screen.
///
/// It replaces two things that were saying half of it each: a KPI strip folded
/// away inside the module header (so the plan, the price and the renewal date
/// were all behind a toggle), and a banner that rendered for five of the eight
/// statuses and stayed silent for the three quietest ones — including `none`,
/// where an office has no licence at all.
///
/// Four facts the payload has always carried and the office was never shown:
/// **`graceEndsAt`** (the date that matters most, in the state it matters in),
/// **`suspendedReason`** (why the platform held the account), **`contractRef`**
/// (which agreement this is), and the fact that the licence has an end date at
/// all when auto-renew is off.
class OfficeSubscriptionCard extends StatelessWidget {
  const OfficeSubscriptionCard({
    super.key,
    required this.license,
    this.onContact,
  });

  final LicenseSummary license;

  /// Opens the upgrade/contact request. Absent in a read-only capture.
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final view = LicenseStatusView.of(license);
    final status = context.status(view.tone);
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBand(view: view, status: status),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlanLine(license: license),
                const SizedBox(height: AppSpacing.small),
                Text(
                  view.headline,
                  style: text.bodyMedium?.copyWith(height: 1.6),
                ),
                if (view.consequence != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  _ConsequenceNote(view: view, status: status),
                ],
                if (license.suspendedReason?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.small),
                  _ReasonNote(reason: license.suspendedReason!.trim()),
                ],
                const SizedBox(height: AppSpacing.large),
                _FactStrip(license: license, view: view),
                if (onContact != null) ...[
                  const SizedBox(height: AppSpacing.large),
                  _ContactRow(view: view, onContact: onContact!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The tone-carrying header. The one place on the screen where colour states the
/// account's condition, so «موقوفة» is legible before a word is read.
class _StatusBand extends StatelessWidget {
  const _StatusBand({required this.view, required this.status});

  final LicenseStatusView view;
  final AppStatusStyle status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: status.tint,
        border: Border(bottom: BorderSide(color: status.accent.withAlpha(70))),
      ),
      child: Row(
        children: [
          Icon(
            view.isRestricted
                ? DashboardIcons.locked
                : (view.needsAction
                      ? DashboardIcons.attention
                      : DashboardIcons.allClear),
            size: 20,
            color: status.ink,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'حالة الاشتراك',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: status.ink,
              ),
            ),
          ),
          DashboardStatusChip(
            label: view.statusLabel,
            color: status.accent.withAlpha(30),
            textColor: status.ink,
          ),
        ],
      ),
    );
  }
}

/// The plan's name at headline weight, with what it costs beside it. The name
/// alone used to carry the visual weight; an owner opening this screen is at
/// least as often asking about the amount.
class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.license});

  final LicenseSummary license;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cycle = licenseCycleLabel(license.billingCycle);
    final name = license.planNameAr.trim();

    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.xSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          name.isEmpty ? 'بدون باقة' : name,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (license.price != null)
          Text(
            cycle.isEmpty
                ? licensingMoney(license.price, license.currency)
                : '${licensingMoney(license.price, license.currency)} · $cycle',
            style: text.titleSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// What happens next, in the tone of the state that produces it.
class _ConsequenceNote extends StatelessWidget {
  const _ConsequenceNote({required this.view, required this.status});

  final LicenseStatusView view;
  final AppStatusStyle status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: status.accent.withAlpha(60)),
      ),
      child: Text(
        view.consequence!,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: status.ink, height: 1.7),
      ),
    );
  }
}

/// `suspendedReason`, written by the platform when it held the account. Parsed
/// since the licence entity was written and never once rendered.
class _ReasonNote extends StatelessWidget {
  const _ReasonNote({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            DashboardIcons.document,
            size: 16,
            color: DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'سبب القرار: ',
                    style: text.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                  TextSpan(
                    text: reason,
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dates and the terms, as a row of labelled facts.
///
/// A [Wrap] of min-width blocks rather than fixed lanes: «التجديد التلقائي» and
/// a contract reference are very different lengths, and a fixed lane clips the
/// long one at 1.6× text scale.
class _FactStrip extends StatelessWidget {
  const _FactStrip({required this.license, required this.view});

  final LicenseSummary license;
  final LicenseStatusView view;

  @override
  Widget build(BuildContext context) {
    final periodStart = license.periodStart;
    final periodEnd = license.periodEnd;

    return Wrap(
      spacing: AppSpacing.xLarge,
      runSpacing: AppSpacing.medium,
      children: [
        if (view.deadline != null)
          _Fact(
            label: view.deadlineLabel ?? 'الموعد التالي',
            value: licensingDate(view.deadline),
            detail: _daysDetail(view),
            // Coloured only when the date is one the owner must act on. An
            // auto-renewing plan that renews tomorrow is not a warning.
            emphasis: view.needsAction && view.deadlineIsImminent
                ? context.status(view.tone).accent
                : null,
          ),
        // Only when the period is a span. With no start date the end date is
        // already the deadline fact beside it, and repeating it under a second
        // label reads as two different dates that happen to match.
        if (periodStart != null)
          _Fact(
            label: 'الفترة الحالية',
            value: 'من ${licensingDate(periodStart)}',
            detail: periodEnd == null
                ? null
                : 'إلى ${licensingDate(periodEnd)}',
          ),
        if (license.status != 'none')
          _Fact(
            label: 'التجديد التلقائي',
            value: license.autoRenew ? 'مفعّل' : 'متوقف',
            detail: license.autoRenew
                ? 'تُصدر الفاتورة تلقائيًا'
                : 'يتطلب تجديدًا يدويًا',
          ),
        if (license.contractRef?.trim().isNotEmpty ?? false)
          _Fact(label: 'مرجع العقد', value: license.contractRef!.trim()),
      ],
    );
  }

  static String? _daysDetail(LicenseStatusView view) {
    final left = view.daysLeft;
    if (left == null) return null;
    if (left < 0) return 'مرّ ${-left} يوم';
    if (left == 0) return 'اليوم';
    return 'باقٍ $left يوم';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.detail,
    this.emphasis,
  });

  final String label;
  final String value;
  final String? detail;

  /// Colours the value when the fact is the one the owner must act on.
  final Color? emphasis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasis,
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: text.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// The one call to action this screen honestly has.
///
/// There is no checkout — a plan change has proration implications that need a
/// billing engine — so the button opens a request the owner can send through
/// whichever channel they already use, rather than a disabled «ترقية» that
/// teaches them the console is broken.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.view, required this.onContact});

  final LicenseStatusView view;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (view.needsAction)
          FilledButton.icon(
            onPressed: onContact,
            icon: const Icon(DashboardIcons.tickets, size: 18),
            label: const Text('تواصل مع إدارة المنصة'),
          )
        else
          OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(DashboardIcons.tickets, size: 18),
            label: const Text('طلب ترقية أو رفع حد'),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'تغيير الباقة يتم من إدارة المنصة، ولا يتم ذاتيًا في هذا الإصدار.',
            style: text.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
      ],
    );
  }
}

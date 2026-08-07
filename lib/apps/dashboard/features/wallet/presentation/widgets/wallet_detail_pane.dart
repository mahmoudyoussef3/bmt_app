import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';
import 'wallet_ledger_entry_tile.dart';

/// Surface 2 — the working screen.
///
/// The layout follows four rules from §8.2, each of which is about what an
/// operator is doing when they open it:
///
///  * **The balance is the single largest element.** It is the one number every
///    conversation starts from.
///  * **Lifetime totals are a strip, not cards.** They are context; five KPI
///    cards would compete with the balance.
///  * **A pending refund surfaces inline as a banner.** An operator must not be
///    able to issue a second refund while unaware one is already waiting.
///  * **Reversed entries stay visible**, struck through and linked to what
///    corrected them.
class WalletDetailPane extends StatelessWidget {
  const WalletDetailPane({
    super.key,
    required this.summary,
    required this.loading,
    required this.busy,
    required this.canAdjust,
    required this.canApprove,
    required this.chainVerification,
    required this.onRefund,
    required this.onCashback,
    required this.onCredit,
    required this.onDebit,
    required this.onFreeze,
    required this.onVerifyChain,
    required this.onReverse,
    required this.onDecideRefund,
  });

  final WalletSummary? summary;
  final bool loading;
  final bool busy;

  /// Holds `walletAdjustments` — may move money.
  final bool canAdjust;

  /// Holds `walletApprovals` — may decide, reverse, freeze and verify.
  final bool canApprove;

  final WalletChainVerification? chainVerification;

  final VoidCallback onRefund;
  final VoidCallback onCashback;
  final VoidCallback onCredit;
  final VoidCallback onDebit;
  final VoidCallback onFreeze;
  final VoidCallback onVerifyChain;
  final void Function(WalletTransaction entry) onReverse;
  final void Function(RefundRequest refund, bool approve) onDecideRefund;

  @override
  Widget build(BuildContext context) {
    if (loading && summary == null) {
      return const DashboardLoading(
        rows: 4,
        showHeader: false,
        scrollable: false,
      );
    }
    final data = summary;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomerHeader(customer: data.customer, wallet: data.wallet),
        const SizedBox(height: AppSpacing.medium),
        _BalanceHero(wallet: data.wallet),
        const SizedBox(height: AppSpacing.medium),
        _ActionBar(
          busy: busy,
          canAdjust: canAdjust,
          canApprove: canApprove,
          frozen: data.wallet.isFrozen,
          onRefund: onRefund,
          onCashback: onCashback,
          onCredit: onCredit,
          onDebit: onDebit,
          onFreeze: onFreeze,
          onVerifyChain: onVerifyChain,
        ),
        const SizedBox(height: AppSpacing.medium),
        _TotalsStrip(summary: data),
        if (chainVerification != null) ...[
          const SizedBox(height: AppSpacing.medium),
          _ChainBanner(result: chainVerification!),
        ],
        if (data.pendingRefunds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          for (final refund in data.pendingRefunds)
            _PendingRefundBanner(
              refund: refund,
              canDecide: canApprove,
              onDecide: onDecideRefund,
            ),
        ],
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.walletDetailLedger,
          icon: Icons.receipt_long_rounded,
          title: 'سجل الحركات',
          subtitle: 'غير قابل للتعديل — كل تصحيح يُسجَّل كحركة عكسية جديدة',
          child: data.entries.isEmpty
              ? const DashboardEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا توجد حركات على هذه المحفظة',
                  message:
                      'تظهر هنا كل عملية استرداد أو كاش باك أو تسوية بمجرد تنفيذها.',
                )
              : Column(
                  children: [
                    for (final entry in data.entries)
                      WalletLedgerEntryTile(
                        entry: entry,
                        // Only an owner may reverse, and only an entry that is
                        // neither a reversal nor already reversed can be.
                        onReverse:
                            canApprove && !entry.isReversal && !entry.isReversed
                            ? () => onReverse(entry)
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customer, required this.wallet});

  final WalletCustomer customer;
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.displayName,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (customer.phone.isNotEmpty) customer.phone,
                  if (customer.createdAt != null)
                    'عميل منذ ${WalletFormat.date(customer.createdAt!)}',
                ].join(' · '),
                style: text.bodySmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
        if (wallet.isFrozen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: palette.active.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.active.withAlpha(110)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ac_unit_rounded, size: 14, color: palette.active),
                const SizedBox(width: 4),
                Text(
                  'محفظة مجمّدة',
                  style: text.labelSmall?.copyWith(
                    color: palette.active,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The balance, deliberately oversized. Everything else on this screen exists to
/// explain this number.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.primary.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرصيد الحالي',
            style: text.labelMedium?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            WalletFormat.money(wallet.balance),
            style: text.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            wallet.exists
                ? '${WalletFormat.count(wallet.entryCount)} حركة · '
                      'إجمالي مضاف ${WalletFormat.money(wallet.lifetimeCredited)} · '
                      'إجمالي مخصوم ${WalletFormat.money(wallet.lifetimeDebited)}'
                : 'لم تُنشأ محفظة لهذا العميل بعد — تُنشأ تلقائيًا مع أول حركة.',
            style: text.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          if (wallet.isFrozen && wallet.frozenReason != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'سبب التجميد: ${wallet.frozenReason}',
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy,
    required this.canAdjust,
    required this.canApprove,
    required this.frozen,
    required this.onRefund,
    required this.onCashback,
    required this.onCredit,
    required this.onDebit,
    required this.onFreeze,
    required this.onVerifyChain,
  });

  final bool busy;
  final bool canAdjust;
  final bool canApprove;
  final bool frozen;
  final VoidCallback onRefund;
  final VoidCallback onCashback;
  final VoidCallback onCredit;
  final VoidCallback onDebit;
  final VoidCallback onFreeze;
  final VoidCallback onVerifyChain;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        // A support agent sees exactly one action here: raise a request. That is
        // their escalation path, and it is a real one — it lands in the owner's
        // queue with an alert attached.
        FilledButton.icon(
          onPressed: busy ? null : onRefund,
          icon: const Icon(Icons.assignment_return_rounded, size: 18),
          label: Text(canApprove ? 'استرداد' : 'طلب استرداد'),
        ),
        if (canAdjust) ...[
          FilledButton.tonalIcon(
            onPressed: busy ? null : onCashback,
            icon: const Icon(Icons.card_giftcard_rounded, size: 18),
            label: const Text('كاش باك'),
          ),
          FilledButton.tonalIcon(
            onPressed: busy ? null : onCredit,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('إضافة رصيد'),
          ),
          OutlinedButton.icon(
            // Disabled rather than hidden while frozen: the operator should see
            // that the action exists and understand why it is unavailable.
            onPressed: busy || frozen ? null : onDebit,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            label: const Text('خصم'),
          ),
        ],
        if (canApprove) ...[
          OutlinedButton.icon(
            onPressed: busy ? null : onFreeze,
            icon: Icon(
              frozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded,
              size: 18,
            ),
            label: Text(frozen ? 'إلغاء التجميد' : 'تجميد'),
          ),
          TextButton.icon(
            onPressed: busy ? null : onVerifyChain,
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: const Text('التحقق من السجل'),
          ),
        ],
      ],
    );
  }
}

/// Lifetime totals per kind. A strip of small tiles, not KPI cards — see the
/// class docs above.
class _TotalsStrip extends StatelessWidget {
  const _TotalsStrip({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return Row(
      children: [
        for (final entry in const [
          (WalletKind.refund, 'مرتجعات'),
          (WalletKind.cashback, 'كاش باك'),
          (WalletKind.manualCredit, 'إضافات'),
          (WalletKind.manualDebit, 'خصومات'),
          (WalletKind.walletSpend, 'مصروف'),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.small),
              child: _TotalTile(
                label: entry.$2,
                value: summary.totalFor(entry.$1),
                tint: switch (entry.$1) {
                  WalletKind.refund => palette.warning,
                  WalletKind.cashback => palette.accent,
                  WalletKind.manualCredit => palette.positive,
                  WalletKind.manualDebit => palette.negative,
                  _ => palette.neutral,
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final double value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              WalletFormat.money(value),
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: value == 0 ? DashboardColors.faintInk(context) : tint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The inline control from §8.2: a waiting request is impossible to miss while
/// standing on the screen where a second refund would be issued.
class _PendingRefundBanner extends StatelessWidget {
  const _PendingRefundBanner({
    required this.refund,
    required this.canDecide,
    required this.onDecide,
  });

  final RefundRequest refund;
  final bool canDecide;
  final void Function(RefundRequest refund, bool approve) onDecide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: palette.warning.withAlpha(24),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: palette.warning.withAlpha(110)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.warning, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${refund.status.label} · ${WalletFormat.money(refund.effectiveAmount)}'
                  '${refund.bookingNumber == null ? '' : ' · حجز #${refund.bookingNumber}'}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  refund.reason,
                  style: text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canDecide) ...[
            TextButton(
              onPressed: () => onDecide(refund, false),
              child: const Text('رفض'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => onDecide(refund, true),
              child: const Text('مراجعة واعتماد'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The verdict of the last chain check, kept on screen rather than left to a
/// snackbar that scrolls away. A failure here is the loudest thing in the module
/// for a reason: the wallet has already been auto-frozen server-side.
class _ChainBanner extends StatelessWidget {
  const _ChainBanner({required this.result});

  final WalletChainVerification result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);
    final tint = result.verified ? palette.positive : scheme.error;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tint.withAlpha(22),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tint.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.verified ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
            color: tint,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.verified
                      ? 'سجل المحفظة سليم'
                      : 'خلل في سجل المحفظة — تم تجميدها تلقائيًا',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.verified
                      ? '${WalletFormat.count(result.entries)} حركة متسلسلة ومتطابقة مع بصمة السلسلة.'
                      : '${result.faultLabel}${result.divergentSeq == null ? '' : ' عند الحركة #${result.divergentSeq}'}.',
                  style: text.bodySmall,
                ),
                if (result.verified && result.headHash != null)
                  Text(
                    'بصمة نهاية السلسلة: ${result.headHash!.substring(0, 16)}…',
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.faintInk(context),
                      fontFamily: 'monospace',
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

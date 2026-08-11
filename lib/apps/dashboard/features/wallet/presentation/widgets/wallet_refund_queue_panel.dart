import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/refund_request.dart';
import 'wallet_format.dart';

/// Surface 4 — the refund requests queue.
///
/// This gives the approval step a home. It has not had one since the Finance
/// rebuild deleted the refund UI (§1.1): `refund_requests` rows have been
/// arriving from the client app and from the alert trigger with nowhere in the
/// dashboard to act on them.
///
/// Every refund in the system is one row here — the support agent's request and
/// the owner's own settled refund are the same record at different stages, which
/// is what makes one queue, one audit trail and one place Finance reads possible.
class WalletRefundQueuePanel extends StatelessWidget {
  const WalletRefundQueuePanel({
    super.key,
    required this.refunds,
    required this.loading,
    required this.canDecide,
    required this.onDecide,
    required this.onOpenCustomer,
    required this.onBatchRefund,
  });

  final List<RefundRequest> refunds;
  final bool loading;
  final bool canDecide;
  final void Function(RefundRequest refund, bool approve) onDecide;
  final void Function(String clientId) onOpenCustomer;
  final VoidCallback onBatchRefund;

  @override
  Widget build(BuildContext context) {
    final pending = refunds.where((r) => r.isOpen).toList();

    return DashboardPanel(
      sectionId: DashboardSectionIds.walletRefundQueue,
      icon: Icons.assignment_return_rounded,
      title: 'طلبات الاسترداد',
      subtitle: loading
          ? 'جارٍ التحميل…'
          : pending.isEmpty
          ? 'لا شيء ينتظر قرارًا'
          : '${WalletFormat.count(pending.length)} طلب بانتظار القرار · '
                'بقيمة ${WalletFormat.money(pending.fold<double>(0, (sum, r) => sum + r.effectiveAmount))}',
      trailing: canDecide
          ? TextButton.icon(
              onPressed: onBatchRefund,
              icon: const Icon(Icons.event_busy_rounded, size: 18),
              label: const Text('استرداد رحلة ملغاة'),
            )
          : null,
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
              child: Center(child: CircularProgressIndicator()),
            )
          : refunds.isEmpty
          ? const DashboardEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'لا توجد طلبات استرداد',
              message:
                  'تظهر هنا طلبات العملاء وطلبات فريق خدمة العملاء بانتظار قرار المالك.',
            )
          : Column(
              children: [
                for (final refund in refunds)
                  _RefundTile(
                    refund: refund,
                    canDecide: canDecide,
                    onDecide: onDecide,
                    onOpenCustomer: onOpenCustomer,
                  ),
              ],
            ),
    );
  }
}

class _RefundTile extends StatelessWidget {
  const _RefundTile({
    required this.refund,
    required this.canDecide,
    required this.onDecide,
    required this.onOpenCustomer,
  });

  final RefundRequest refund;
  final bool canDecide;
  final void Function(RefundRequest refund, bool approve) onDecide;
  final void Function(String clientId) onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tint = WalletFormat.refundColor(refund.status, context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tint.withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tint.withAlpha(110)),
                ),
                child: Text(
                  refund.status.label,
                  style: text.labelSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            refund.clientName ?? 'حجز بدون حساب عميل',
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (refund.clientId != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            tooltip: 'فتح محفظة العميل',
                            onPressed: () => onOpenCustomer(refund.clientId!),
                            icon: const Icon(Icons.open_in_new_rounded),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      refund.reason,
                      style: text.bodySmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                WalletFormat.money(refund.effectiveAmount),
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: 4,
            children: [
              _Meta(icon: Icons.sell_outlined, label: refund.categoryLabel),
              _Meta(
                icon: refund.fromClient
                    ? Icons.phone_iphone_rounded
                    : Icons.desktop_windows_outlined,
                label: refund.fromClient
                    ? 'من تطبيق العميل'
                    : 'من ${refund.requestedByName ?? 'لوحة التحكم'}',
              ),
              if (refund.bookingNumber != null)
                _Meta(
                  icon: Icons.confirmation_number_outlined,
                  label: 'حجز #${refund.bookingNumber}',
                ),
              _Meta(
                icon: Icons.schedule_rounded,
                label: WalletFormat.dateTime(refund.createdAt),
              ),
              if (refund.settlement != null)
                _Meta(
                  icon: Icons.account_balance_rounded,
                  label: refund.settlement!.label,
                ),
              
              if (refund.batchId != null)
                _Meta(icon: Icons.layers_outlined, label: 'ضمن استرداد جماعي'),
            ],
          ),
          if (canDecide && refund.isOpen) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onDecide(refund, false),
                  child: const Text('رفض'),
                ),
                const SizedBox(width: AppSpacing.small),
                FilledButton(
                  onPressed: () => onDecide(refund, true),
                  child: const Text('اعتماد وتنفيذ'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = DashboardColors.faintInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

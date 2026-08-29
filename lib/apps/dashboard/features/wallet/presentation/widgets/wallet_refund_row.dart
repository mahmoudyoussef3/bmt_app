import 'package:flutter/material.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';
import 'wallet_row_shell.dart';

/// One refund request — surface 3's row.
///
/// Every refund in the system is one row here: the customer's request from the
/// app, the support agent's request from the console and the owner's own
/// settled refund are the same record at different stages, which is what makes
/// one queue, one audit trail and one place Finance reads possible.
///
/// The decision lives on the row, under the context that justifies it. Putting
/// «اعتماد وتنفيذ» beside the amount — where the old tile had it — made the
/// button compete with the figure it acts on.
class WalletRefundRow extends StatelessWidget {
  const WalletRefundRow({
    super.key,
    required this.refund,
    required this.canDecide,
    required this.onDecide,
    required this.onOpenCustomer,
  });

  final RefundRequest refund;

  /// `walletApprovals`. A support agent sees the queue and cannot clear it —
  /// which is what makes escalation work instead of guesswork.
  final bool canDecide;

  final void Function(RefundRequest refund, bool approve) onDecide;
  final void Function(String clientId) onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    final tint = WalletFormat.refundColor(refund.status, context);
    final clientId = refund.clientId;

    return WalletRowShell(
      tone: tint,
      leadingIcon: switch (refund.status) {
        RefundStatus.settled => Icons.check_circle_outline_rounded,
        RefundStatus.approved => Icons.task_alt_rounded,
        RefundStatus.pending => Icons.pending_actions_rounded,
        RefundStatus.rejected ||
        RefundStatus.failed => Icons.do_not_disturb_on_outlined,
        RefundStatus.cancelled => Icons.remove_circle_outline_rounded,
      },
      title: refund.clientName ?? 'حجز بدون حساب عميل',
      chips: [
        WalletRowChip(label: refund.status.label, tone: tint),
        WalletRowChip(label: refund.categoryLabel),
      ],
      subtitle: refund.reason,
      meta: [
        WalletRowMeta(
          refund.fromClient
              ? Icons.phone_iphone_rounded
              : Icons.desktop_windows_outlined,
          refund.fromClient
              ? 'من تطبيق العميل'
              : 'من ${refund.requestedByName ?? 'لوحة التحكم'}',
        ),
        if (refund.bookingNumber != null)
          WalletRowMeta(
            Icons.confirmation_number_outlined,
            'حجز #${refund.bookingNumber}',
          ),
        WalletRowMeta(
          Icons.schedule_rounded,
          WalletFormat.dateTime(refund.createdAt),
        ),
        if (refund.settlement != null)
          WalletRowMeta(
            Icons.account_balance_rounded,
            refund.settlement!.label,
          ),
        if (refund.batchId != null)
          WalletRowMeta(Icons.layers_outlined, 'ضمن استرداد جماعي'),
      ],
      amount: WalletFormat.money(refund.effectiveAmount),
      // What was *decided* against what was asked for, when they differ — a
      // partially approved refund must never read as if the office paid the
      // whole claim.
      amountNote: refund.approvedAmount == null
          ? 'المبلغ المطلوب'
          : refund.approvedAmount == refund.amount
          ? 'المبلغ المعتمد'
          : 'اعتُمد من ${WalletFormat.money(refund.amount)}',
      actions: [
        if (clientId != null)
          TextButton.icon(
            onPressed: () => onOpenCustomer(clientId),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('فتح المحفظة'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        if (canDecide && refund.isOpen) ...[
          TextButton(
            onPressed: () => onDecide(refund, false),
            child: const Text('رفض'),
          ),
          FilledButton(
            onPressed: () => onDecide(refund, true),
            child: const Text('اعتماد وتنفيذ'),
          ),
        ],
      ],
    );
  }
}

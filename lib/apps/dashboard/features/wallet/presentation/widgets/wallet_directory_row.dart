import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';
import 'wallet_row_shell.dart';

/// One customer in the directory — surface 1's row.
///
/// The directory is the module's foundation rather than a nicety: the dashboard
/// has no customer entity at all, so "who are my customers and what do I owe
/// them" had no home before it. It is also the only entry point to money
/// movement, because a context-free "adjust a balance" form is precisely the
/// control weakness this module exists to remove.
///
/// It is drawn on [WalletRowShell] like the ledger and the refund queue: the
/// balance sits in the same money lane as a posting's amount and a refund's
/// value, so the three tabs' figures line up down the page.
class WalletDirectoryRow extends StatelessWidget {
  const WalletDirectoryRow({
    super.key,
    required this.entry,
    required this.now,
    required this.selected,
    required this.onTap,
  });

  final WalletDirectoryEntry entry;

  /// One clock for the whole list, so every "منذ ٣ ساعات" on the page agrees.
  final DateTime now;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final frozen = entry.walletStatus == WalletStatus.frozen;
    final warning = DashboardColors.status(context, AppStatusTone.warning);
    final funded = DashboardColors.status(context, AppStatusTone.info);

    return WalletRowShell(
      // A balance is not a status, so a funded wallet is not "good" and an
      // empty one is not "bad": the tone marks the two states that need an
      // operator's attention — frozen, and money still held — and leaves the
      // rest of the list quiet.
      tone: frozen
          ? warning.accent
          : entry.balance > 0
          ? funded.accent
          : DashboardColors.mutedInk(context),
      leadingIcon: frozen
          ? Icons.ac_unit_rounded
          : Icons.person_outline_rounded,
      title: entry.displayName,
      chips: [
        if (frozen) WalletRowChip(label: 'مجمّدة', tone: warning.accent),
        if (entry.pendingRefunds > 0)
          WalletRowChip(
            label: '${WalletFormat.count(entry.pendingRefunds)} طلب استرداد',
            tone: warning.accent,
          ),
      ],
      subtitle: entry.phone.isEmpty ? '—' : entry.phone,
      meta: [
        WalletRowMeta(
          Icons.history_rounded,
          WalletFormat.age(entry.lastActivityAt, now),
        ),
        WalletRowMeta(
          Icons.receipt_long_outlined,
          '${WalletFormat.count(entry.entryCount)} حركة',
        ),
      ],
      amount: WalletFormat.money(entry.balance),
      // Not «الرصيد الحالي» — that phrase belongs to the detail pane's headline
      // figure, and two of it on one screen makes the eye check which is which.
      amountNote: 'رصيد المحفظة',
      selected: selected,
      onTap: onTap,
    );
  }
}

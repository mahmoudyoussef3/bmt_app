import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/client_wallet.dart';

/// What each kind of ledger line is called, in the rider's language.
///
/// The domain enum carries an Arabic `label` of its own, but a domain type
/// cannot know which locale is on screen — so the wording a rider reads is
/// resolved here, where there is a [BuildContext] to resolve it against. The
/// enum's own field keeps its name, so this one has to differ.
extension ClientWalletEntryKindLabel on ClientWalletEntryKind {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;

    return switch (this) {
      ClientWalletEntryKind.refund => l10n.wallet_kindRefund,
      ClientWalletEntryKind.cashback => l10n.wallet_kindCashback,
      ClientWalletEntryKind.manualCredit => l10n.wallet_kindManualCredit,
      ClientWalletEntryKind.manualDebit => l10n.wallet_kindManualDebit,
      ClientWalletEntryKind.walletSpend => l10n.wallet_kindWalletSpend,
      ClientWalletEntryKind.walletTopup => l10n.wallet_kindWalletTopup,
      ClientWalletEntryKind.reversal => l10n.wallet_kindReversal,
    };
  }
}

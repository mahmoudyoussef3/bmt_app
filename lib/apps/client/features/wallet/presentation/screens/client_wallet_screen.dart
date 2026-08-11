import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_app_bar.dart';
import 'package:bmt_app/apps/client/core/widgets/client_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/client_wallet_cubit.dart';
import '../widgets/client_wallet_entry_tile.dart';
import '../widgets/client_wallet_office_card.dart';

/// محفظتي — the rider's read-only view of what each office owes them.
///
/// Three deliberate choices, all of them about honesty:
///
///  * **One card per office, never one merged balance.** Value collected by one
///    office is not spendable at another, and a single pooled number would be a
///    promise the platform cannot keep.
///  * **No redeem button.** V1 has no wallet spending; the balance is applied by
///    the office. The previous screen had a redeem action that zeroed a balance
///    client-side, was denied by RLS without throwing, and congratulated the
///    rider on a payout that never happened.
///  * **Every entry shows the balance it produced.** The rider's question is
///    "why is my balance this", and an amount on its own cannot answer it.
class ClientWalletScreen extends StatelessWidget {
  const ClientWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: ClientAppBar(
        title: l10n.wallet_title,
        subtitle: l10n.wallet_subtitle,
      ),
      body: SafeArea(
        child: BlocBuilder<ClientWalletCubit, ClientWalletState>(
          builder: (context, state) => switch (state) {
            ClientWalletLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ClientWalletError(:final message) => ClientErrorCard.fullScreen(
              message: message,
              retryLabel: l10n.common_retry,
              onRetry: () => context.read<ClientWalletCubit>().load(),
            ),
            ClientWalletLoaded() => _WalletBody(state: state),
          },
        ),
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.state});

  final ClientWalletLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientWalletCubit>();
    final summary = state.summary;

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ClientSpacing.screen,
        children: [
          
          if (!summary.isEmpty) ...[
            _TotalCard(
              total: summary.totalBalance,
              officeCount: summary.wallets.length,
            ),
            const SizedBox(height: ClientSpacing.md),
          ],
          if (summary.isEmpty)
            const _EmptyWallet()
          else
            for (final wallet in summary.wallets)
              Padding(
                padding: const EdgeInsets.only(bottom: ClientSpacing.md),
                child: ClientWalletOfficeCard(
                  wallet: wallet,
                  expanded: state.expandedWalletId == wallet.walletId,
                  onToggle: () => cubit.toggleWallet(wallet.walletId),
                  entryBuilder: (entry) => ClientWalletEntryTile(entry: entry),
                ),
              ),
        ],
      ),
    );
  }
}

/// The sum across offices, labelled as what it is.
///
/// It is shown because "how much credit do I have anywhere" is a fair question,
/// and hidden behind a caption because it is *not* a spendable pot: each pound
/// belongs to the office that took it.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.officeCount});

  final double total;
  final int officeCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ClientCard(
      backgroundColor: scheme.primary.withAlpha(18),
      borderColor: scheme.primary.withAlpha(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.wallet_totalLabel,
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            FormatUtil.currency(context, total),
            style: text.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            officeCount <= 1
                ? context.l10n.wallet_totalOneOffice
                : context.l10n.wallet_totalManyOffices(officeCount),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ClientCard(
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 44,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: ClientSpacing.sm),
          Text(
            context.l10n.wallet_emptyTitle,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            context.l10n.wallet_emptyBody,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

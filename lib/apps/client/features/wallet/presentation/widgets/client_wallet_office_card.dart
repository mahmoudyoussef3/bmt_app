import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_card.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/client_wallet.dart';

/// One office's balance, with its history folded away underneath.
///
/// The office is named on the card because that is the whole point of the model:
/// this is credit with *that* business, not a platform balance. Collapsing the
/// history keeps the answer to "how much do I have" one glance away, and the
/// answer to "why" one tap away.
class ClientWalletOfficeCard extends StatelessWidget {
  const ClientWalletOfficeCard({
    super.key,
    required this.wallet,
    required this.expanded,
    required this.onToggle,
    required this.entryBuilder,
  });

  final ClientWallet wallet;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget Function(ClientWalletEntry entry) entryBuilder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ClientCard(
      onTap: wallet.entries.isEmpty ? null : onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              
              OfficeLogoAvatar(logoUrl: wallet.officeLogoUrl, size: 44),
              const SizedBox(width: ClientSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.officeName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.l10n.wallet_entryCount(wallet.entryCount),
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: ClientSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatUtil.currency(context, wallet.balance),
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: wallet.hasBalance
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (wallet.entries.isNotEmpty)
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
          if (wallet.isFrozen) ...[
            const SizedBox(height: ClientSpacing.sm),
            
            Container(
              padding: const EdgeInsets.all(ClientSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(ClientRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pause_circle_outline_rounded,
                    size: 18,
                    color: scheme.error,
                  ),
                  const SizedBox(width: ClientSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.wallet_frozenNotice,
                      style: text.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (expanded && wallet.entries.isNotEmpty) ...[
            const SizedBox(height: ClientSpacing.sm),
            Divider(color: scheme.outlineVariant.withAlpha(120)),
            const SizedBox(height: ClientSpacing.xs),
            for (final entry in wallet.entries) entryBuilder(entry),
            if (wallet.entryCount > wallet.entries.length)
              Padding(
                padding: const EdgeInsets.only(top: ClientSpacing.xs),
                child: Text(
                  
                  context.l10n.wallet_entriesTruncated(wallet.entries.length),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

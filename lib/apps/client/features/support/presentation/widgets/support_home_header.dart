import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Support Center hero. It carries the screen's single call to action: the
/// Support Center is a ticket workflow, not a category browser, so the client
/// always arrives at the same "Create a ticket" door and picks the topic
/// inside the form.
class SupportHomeHeader extends StatelessWidget {
  const SupportHomeHeader({super.key, required this.onCreateTicket});

  final VoidCallback onCreateTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primaryFor(context).withAlpha(50),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.l10n.support_heroTitle,
                  style: ClientTypography.headingMedium(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.support_heroBody,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: Colors.white.withAlpha(220), height: 1.5),
          ),
          const SizedBox(height: 20),
          _CreateTicketButton(onTap: onCreateTicket),
        ],
      ),
    );
  }
}

/// Light-on-gradient CTA. Deliberately not [ClientButton] — the primary
/// variant's blue fill would disappear into the hero's blue gradient.
class _CreateTicketButton extends StatelessWidget {
  const _CreateTicketButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primary;

    return PressableScale(
      onTap: onTap,
      scale: 0.97,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: primary),
            const SizedBox(width: 8),
            Text(
              context.l10n.support_createTicket,
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(color: primary, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Shown when the booking reached checkout with pieces missing — no seat, no
/// fare, no trip. It names what is missing and sends the rider back to fix it,
/// rather than letting them press pay into a failure.
class CheckoutNotice extends StatelessWidget {
  const CheckoutNotice({
    super.key,
    required this.missing,
    required this.onFix,
  });

  final List<String> missing;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final tone = ClientColors.journeyBadgeFor(
      context,
      ClientJourneyStatus.departing,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(ClientRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem_rounded, size: 18, color: tone.label),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This booking is missing ${_list(missing)}',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: tone.fg, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Go back and complete it before paying.',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: tone.fg),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onFix, child: const Text('Go back')),
        ],
      ),
    );
  }

  String _list(List<String> items) {
    final lower = items.map((item) => item.toLowerCase()).toList();
    if (lower.length == 1) return '${lower.first}.';
    return '${lower.sublist(0, lower.length - 1).join(', ')} and ${lower.last}.';
  }
}

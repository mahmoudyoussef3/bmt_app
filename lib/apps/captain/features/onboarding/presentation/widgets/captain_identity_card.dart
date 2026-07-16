import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

/// Who the app thinks this captain is: name, phone, employee code.
class CaptainIdentityCard extends StatelessWidget {
  const CaptainIdentityCard({super.key, required this.session});

  final CaptainLocalSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = session.name.trim();
    final first = name.isEmpty ? '' : name.split(' ').first;

    return CaptainCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primary.withAlpha(28),
            child: Text(
              first.isEmpty ? '؟' : first.characters.first,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً${first.isEmpty ? '' : '، $first'} 👋',
                  style: CaptainTypography.titleLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    session.phone,
                    style: CaptainTypography.bodyMedium(
                      context,
                    ).copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                if (session.employeeCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'كود الكابتن: ${session.employeeCode}',
                    style: CaptainTypography.labelSmall(
                      context,
                    ).copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

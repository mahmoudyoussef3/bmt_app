import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_state.dart';
import 'offices_search_field.dart';

/// The directory's fixed band: a lead line, the search box, and — only while a
/// query narrows the list — how many operators survived it.
///
/// It is pinned above the list rather than scrolling with it. A rider filtering
/// a directory reaches for the box repeatedly, and it must not be somewhere up
/// the scroll when they do.
class OfficesSearchBand extends StatelessWidget {
  const OfficesSearchBand({super.key, required this.state});

  final OfficesDirectoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = state.query.trim().isNotEmpty;

    final accent = ClientColors.primaryFor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfficesSearchField(query: state.query),
          if (searching) ...[
            const SizedBox(height: ClientSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(ClientRadius.pill),
              ),
              child: Text(
                l10n.offices_matchesLabel(state.visibleOffices.length),
                style: ClientTypography.labelSmall(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

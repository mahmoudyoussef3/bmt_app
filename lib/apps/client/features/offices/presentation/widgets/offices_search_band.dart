import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/offices_directory_state.dart';
import 'offices_search_field.dart';

/// The masthead's lower half: the search box, and — only while a query narrows
/// the list — how many operators survived it.
///
/// The box sits on the band's bottom edge rather than in the page below it, so
/// it reads as part of the header's furniture and stays put while the list
/// scrolls under it.
class OfficesSearchBand extends StatelessWidget {
  const OfficesSearchBand({super.key, required this.state});

  final OfficesDirectoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = state.query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.lg,
        ClientSpacing.sm,
        ClientSpacing.lg,
        ClientSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfficesSearchField(query: state.query),
          if (searching) ...[
            const SizedBox(height: ClientSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 13,
                  color: Colors.white.withAlpha(210),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.offices_matchesLabel(state.visibleOffices.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

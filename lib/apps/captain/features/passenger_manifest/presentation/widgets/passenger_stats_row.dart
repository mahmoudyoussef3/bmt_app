import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../cubit/passenger_manifest_state.dart';

/// How far boarding has got, in one bar.
///
/// This used to be four number tiles — boarded, waiting, absent, expected —
/// above the bar. The filter chips underneath now carry the same three counts
/// *and* let the captain act on them, so the tiles were the same figures stated
/// twice, one copy of which did nothing. What is left is the one thing the
/// chips cannot say: how close the vehicle is to full.
class PassengerStatsRow extends StatelessWidget {
  const PassengerStatsRow({super.key, required this.counts});

  final PassengerCounts counts;

  @override
  Widget build(BuildContext context) {
    final done = counts.expected > 0 && counts.boarded >= counts.expected;
    final tint = done
        ? CaptainColors.successFor(context)
        : CaptainColors.primaryInkFor(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s4,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br16,
          border: CaptainDesignTokens.hairline(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    done ? 'اكتمل صعود الركاب' : 'الركاب الصاعدون',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.labelMedium(context).copyWith(
                      color: done
                          ? tint
                          : CaptainColors.textSecondaryFor(context),
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: CaptainDesignTokens.s8),
                // A tally reads left-to-right in any locale.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${counts.boarded} / ${counts.expected}',
                    style: CaptainTypography.labelMedium(context).copyWith(
                      color: CaptainColors.textPrimaryFor(context),
                      letterSpacing: 0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CaptainDesignTokens.s8),
            ClipRRect(
              borderRadius: CaptainDesignTokens.brPill,
              child: LinearProgressIndicator(
                value: counts.boardedRatio,
                minHeight: 8,
                backgroundColor: CaptainColors.surfaceAltFor(context),
                valueColor: AlwaysStoppedAnimation<Color>(tint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../models/wallet_views.dart';
import 'wallet_format.dart';

/// The frame every list in محفظة العملاء is rendered in.
///
/// Results header → rows → pager, in that order, on all three tabs. Before
/// this the module answered "how much of this am I looking at" three different
/// ways — a subtitle on the directory panel, a footnote under the ledger, and
/// nothing at all on the refund queue — so the same question needed a different
/// eye movement per tab, and one tab simply never answered it.
///
/// Rows come in already built and are divided by the frame rather than by
/// themselves: a list of individually bordered cards reads as a stack of
/// unrelated things, and these are rows of one record set.
class WalletListSection extends StatelessWidget {
  const WalletListSection({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
    required this.total,
    required this.noun,
    required this.page,
    required this.onPageChanged,
    this.loading = false,
    this.actions = const [],
    this.empty,
    this.totalNote,
    this.capReached = false,
    this.capRows,
  });

  final IconData icon;

  /// What this list is — «قائمة العملاء», «الحركات المالية».
  final String title;

  /// The rows of the **current page**, already built by the tab.
  final List<Widget> rows;

  /// Everything the filters matched, which is what the range is counted
  /// against. Not the same as `rows.length` — that is one page of it.
  final int total;

  /// The unit the total is counted in — «عميل», «حركة», «طلب».
  final String noun;

  final int page;
  final ValueChanged<int> onPageChanged;

  final bool loading;

  /// Controls acting on the whole list: an export, a batch action.
  final List<Widget> actions;

  /// Rendered in place of the rows when there are none. Pass a
  /// [DashboardEmptyState] so the reason and the way out are both stated.
  final Widget? empty;

  /// Appended to the pager's running total, for a window that needs a word the
  /// range cannot carry — "من ٣٤٠ عميلاً في المكتب — ابحث للوصول لغيرهم".
  ///
  /// It goes on the pager rather than beside the range because the range sits
  /// in a one-line header that ellipsises, and this sentence is the part that
  /// would be cut. The pager bar wraps.
  final String? totalNote;

  /// True when the server returned its ceiling rather than everything that
  /// matched, so the list can say which end of the record it is showing.
  ///
  /// Only for a list the server hands back **newest first** — that is the
  /// sentence [DashboardCapNotice] writes. A window that is not ordered by
  /// recency says so through [subtitleNote] instead of borrowing a claim about
  /// time that is not true of it.
  final bool capReached;
  final int? capRows;

  @override
  Widget build(BuildContext context) {
    final showing = rows.length;
    final first = showing == 0 ? 0 : page * walletPageSize + 1;
    final last = first == 0 ? 0 : first + showing - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardResultsHeader(
          icon: icon,
          title: title,
          subtitle: loading
              ? 'جارٍ التحميل…'
              : showing == 0
              ? 'لا نتائج'
              : 'عرض ${WalletFormat.count(first)}–${WalletFormat.count(last)} '
                    'من ${WalletFormat.count(total)}',
          actions: actions,
        ),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xLarge),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: empty ?? const SizedBox.shrink(),
                )
              else
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: DashboardColors.divider(context)),
                  rows[i],
                ],
              if (!loading && rows.isNotEmpty) ...[
                Divider(height: 1, color: DashboardColors.divider(context)),
                DashboardPagerBar(
                  totalLabel:
                      'الإجمالي ${WalletFormat.count(total)} $noun'
                      '${totalNote == null ? '' : ' · $totalNote'}',
                  currentPage: page,
                  pages: walletPageCount(total),
                  onPageChanged: onPageChanged,
                ),
              ],
            ],
          ),
        ),
        if (capReached && capRows != null) ...[
          const SizedBox(height: AppSpacing.small),
          DashboardCapNotice(rowCap: capRows!, noun: noun),
        ],
      ],
    );
  }
}

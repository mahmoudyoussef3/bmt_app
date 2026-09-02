import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/captain_request.dart';
import '../cubit/captain_requests_state.dart';
import '../models/captain_request_sort.dart';
import 'captain_request_card.dart';
import 'captain_requests_format.dart';
import 'captain_requests_table.dart';

/// The joining queue: the shared results header, then the table at desktop
/// widths and a card list below [kDashboardTableBreakpoint] — both paged by the
/// same index, so narrowing the window never moves the operator to a different
/// set of rows.
///
/// Composed exactly like الشكاوى' desk and العملاء' directory, which is what
/// makes الأسطول section read as the same console: results header → rows → one
/// pagination bar, whichever layout is on screen.
class CaptainRequestsBoard extends StatefulWidget {
  const CaptainRequestsBoard({
    super.key,
    required this.state,
    required this.onApprove,
    required this.onReject,
    required this.onSort,
    required this.onClearFilters,
  });

  final CaptainRequestsLoaded state;
  final ValueChanged<CaptainRequest> onApprove;
  final ValueChanged<CaptainRequest> onReject;
  final ValueChanged<CaptainRequestSort> onSort;
  final VoidCallback onClearFilters;

  @override
  State<CaptainRequestsBoard> createState() => _CaptainRequestsBoardState();
}

class _CaptainRequestsBoardState extends State<CaptainRequestsBoard> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant CaptainRequestsBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new filter or queue can shrink the result set out from under the
    // current page — land back on the last real page rather than an empty one.
    final maxPage = _pageCount - 1;
    if (_page > maxPage) _page = maxPage;
  }

  List<CaptainRequest> get _ordered => widget.state.visibleRequests;

  int get _pageCount =>
      (_ordered.length / captainRequestsPageSize).ceil().clamp(1, 99999);

  List<CaptainRequest> get _pageItems {
    final ordered = _ordered;
    final start = (_page * captainRequestsPageSize).clamp(0, ordered.length);
    final end = (start + captainRequestsPageSize).clamp(0, ordered.length);
    return ordered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _pageItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsHeader(
          total: _ordered.length,
          page: _page,
          showing: rows.length,
        ),
        const SizedBox(height: AppSpacing.small),
        if (rows.isEmpty)
          // Bare, not inside an AppCard: DashboardEmptyState draws its own
          // bordered surface, and the two together read as a panel in a panel.
          _EmptyQueue(
            state: widget.state,
            onClearFilters: widget.onClearFilters,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < kDashboardTableBreakpoint) {
                return _RequestCardList(
                  rows: rows,
                  total: _ordered.length,
                  page: _page,
                  pages: _pageCount,
                  onPageChanged: (page) => setState(() => _page = page),
                  onApprove: widget.onApprove,
                  onReject: widget.onReject,
                );
              }
              return CaptainRequestsTable(
                state: widget.state,
                rows: rows,
                pageIndex: _page,
                onPageChanged: (page) => setState(() => _page = page),
                onSort: (sort) {
                  widget.onSort(sort);
                  setState(() => _page = 0);
                },
                onApprove: widget.onApprove,
                onReject: widget.onReject,
              );
            },
          ),
      ],
    );
  }
}

/// What this list is, and how much of it is on screen — the same strip every
/// other list module puts above its rows.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.total,
    required this.page,
    required this.showing,
  });

  final int total;
  final int page;
  final int showing;

  @override
  Widget build(BuildContext context) {
    final first = showing == 0 ? 0 : page * captainRequestsPageSize + 1;
    final last = first == 0 ? 0 : first + showing - 1;

    return DashboardResultsHeader(
      icon: DashboardIcons.captainRequests,
      title: 'قائمة الطلبات',
      subtitle: showing == 0
          ? 'لا توجد نتائج'
          : 'عرض ${CaptainRequestsFormat.count(first)}–'
                '${CaptainRequestsFormat.count(last)} '
                'من ${CaptainRequestsFormat.count(total)}',
    );
  }
}

/// The card layout the queue falls back to below the table breakpoint, closing
/// on the same [DashboardPagerBar] the table uses so the two never disagree
/// about which page is in view.
class _RequestCardList extends StatelessWidget {
  const _RequestCardList({
    required this.rows,
    required this.total,
    required this.page,
    required this.pages,
    required this.onPageChanged,
    required this.onApprove,
    required this.onReject,
  });

  final List<CaptainRequest> rows;
  final int total;
  final int page;
  final int pages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CaptainRequest> onApprove;
  final ValueChanged<CaptainRequest> onReject;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = dashboardCardColumnsFor(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (columns == 1)
              for (final request in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: CaptainRequestCard(
                    request: request,
                    onApprove: () => onApprove(request),
                    onReject: () => onReject(request),
                  ),
                )
            else
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final request in rows)
                    SizedBox(
                      width:
                          (constraints.maxWidth -
                              AppSpacing.small * (columns - 1)) /
                          columns,
                      child: CaptainRequestCard(
                        request: request,
                        onApprove: () => onApprove(request),
                        onReject: () => onReject(request),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.small),
            DashboardPagerBar(
              totalLabel: 'الإجمالي ${CaptainRequestsFormat.count(total)} طلب',
              currentPage: page,
              pages: pages,
              onPageChanged: onPageChanged,
            ),
          ],
        );
      },
    );
  }
}

/// Why the queue is empty, which is two different situations: a filter that
/// matched nothing, and an office nobody has applied to yet. Only the first has
/// a reset button to offer.
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.state, required this.onClearFilters});

  final CaptainRequestsLoaded state;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    // "Nobody has applied yet" is a different situation from "this queue is
    // empty", and only the second has a filter to reset. Keyed on the whole
    // feed rather than on the filters, because the module opens on the pending
    // tab — a filter is always in force, so testing the filters alone would
    // greet a brand-new office with "no matching results".
    if (state.requests.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.captainRequests,
        title: 'لا توجد طلبات انضمام بعد',
        message:
            'يتقدّم السائقون بطلب الانضمام من تطبيق الكابتن، ويظهر الطلب هنا '
            'فور إرساله لتقبله أو ترفضه.',
      );
    }

    return DashboardEmptyState(
      icon: DashboardIcons.captainRequests,
      title: 'لا توجد نتائج مطابقة',
      message: 'جرّب فتح «كل الطلبات» أو إزالة بعض عوامل التصفية.',
      action: OutlinedButton.icon(
        onPressed: onClearFilters,
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('إعادة ضبط التصفية'),
      ),
    );
  }
}

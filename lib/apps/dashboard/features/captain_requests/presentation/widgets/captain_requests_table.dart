import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/captain_request.dart';
import '../cubit/captain_requests_state.dart';
import '../models/captain_request_sort.dart';
import 'captain_request_status_badge.dart';
import 'captain_requests_format.dart';

/// The joining queue as an [OpsDataTable] — the same table shell الحجوزات,
/// الاشتراكات, العملاء and الشكاوى render, so الأسطول section pages, sorts and
/// reads identically to the rest of the console.
///
/// The ordering and the page live in [CaptainRequestsLoaded] and in the board
/// above this widget rather than in private state here: the toolbar's pinned
/// sort control and these column headers must drive one value, and the results
/// header above the rows has to know which slice is on screen.
///
/// ## Which columns are real
///
/// The design's «الرخصة» and «الخبرة» columns have no column behind them —
/// `captain_requests` stores a name, a phone, a free-text note and the two
/// timestamps, and nothing else. Inventing a licence class or a years-of-
/// experience figure is the fabrication this console refuses everywhere else,
/// so those two slots carry what the applicant actually sent (their phone and
/// their own note) and the decision date the office actually recorded.
class CaptainRequestsTable extends StatelessWidget {
  const CaptainRequestsTable({
    super.key,
    required this.state,
    required this.rows,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onSort,
    required this.onApprove,
    required this.onReject,
  });

  final CaptainRequestsLoaded state;

  /// The page of rows to draw, already filtered, ordered and sliced by the
  /// board.
  final List<CaptainRequest> rows;

  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CaptainRequestSort> onSort;
  final ValueChanged<CaptainRequest> onApprove;
  final ValueChanged<CaptainRequest> onReject;

  /// Column index → sort key. Indices absent from this map are not sortable.
  static const _sortColumns = <int, CaptainRequestSort>{
    0: CaptainRequestSort.name,
    3: CaptainRequestSort.requestedAt,
    4: CaptainRequestSort.reviewedAt,
  };

  int? get _sortColumnIndex {
    for (final entry in _sortColumns.entries) {
      if (entry.value == state.sort) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = state.visibleRequests.length;
    final pendingTint = context.status(AppStatusTone.warning).tint;

    return OpsDataTable(
      // `flex` equals each column's own `minWidth`: the table distributes a
      // row's width by flex *fraction*, so any other pairing lets a column be
      // squeezed under its stated minimum at the exact-minWidth boundary.
      columns: const [
        OpsColumn('السائق', flex: 220, minWidth: 220, sortable: true),
        OpsColumn('الهاتف', flex: 150, minWidth: 150),
        OpsColumn('ملاحظة الطلب', flex: 240, minWidth: 240),
        OpsColumn('تاريخ الطلب', flex: 140, minWidth: 140, sortable: true),
        OpsColumn('تاريخ القرار', flex: 140, minWidth: 140, sortable: true),
        OpsColumn('الحالة', flex: 130, minWidth: 130),
        OpsColumn('إجراءات', flex: 132, minWidth: 132),
      ],
      rows: [for (final r in rows) _row(context, r)],
      // The queue's own work, tinted: a request still waiting on a decision is
      // the row the operator opened this screen for.
      rowTints: [for (final r in rows) r.isPending ? pendingTint : null],
      total: total,
      totalLabel: 'الإجمالي ${CaptainRequestsFormat.count(total)} طلب',
      currentPage: pageIndex,
      pageSize: captainRequestsPageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: _sortColumnIndex,
      sortDirection: state.sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: (index) {
        final key = _sortColumns[index];
        if (key != null) onSort(key);
      },
    );
  }

  List<Widget> _row(BuildContext context, CaptainRequest r) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return [
      _DriverIdentityCell(request: r),
      // A first-strong isolate rather than a forced direction: the dashboard's
      // RTL guard bans the forced-direction constant outright in feature code
      // (and scans for the literal, so it cannot even be named here), while an
      // isolate keeps the digits reading left-to-right without one.
      Text(
        isolatedPlaceName(r.phone),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        _noteOf(r),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: muted),
      ),
      _DateCell(
        value: CaptainRequestsFormat.date(r.createdAt),
        detail: CaptainRequestsFormat.age(r.createdAt, DateTime.now()),
      ),
      r.reviewedAt == null
          ? Text('—', style: theme.textTheme.bodySmall?.copyWith(color: muted))
          : _DateCell(
              value: CaptainRequestsFormat.date(r.reviewedAt!),
              detail: CaptainRequestsFormat.age(r.reviewedAt!, DateTime.now()),
            ),
      CaptainRequestStatusBadge(status: r.status),
      _RowActions(
        request: r,
        onApprove: () => onApprove(r),
        onReject: () => onReject(r),
      ),
    ];
  }

  /// The note column carries whichever text is the operator's business on this
  /// row: the office's own rejection reason once one is recorded, otherwise
  /// what the applicant wrote.
  static String _noteOf(CaptainRequest r) {
    final reason = r.rejectionReason?.trim() ?? '';
    if (r.status == CaptainRequestStatus.rejected && reason.isNotEmpty) {
      return 'سبب الرفض: $reason';
    }
    final note = r.note?.trim() ?? '';
    return note.isEmpty ? '—' : note;
  }
}

class _DriverIdentityCell extends StatelessWidget {
  const _DriverIdentityCell({required this.request});

  final CaptainRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = request.fullName.isNotEmpty
        ? request.fullName.characters.first
        : '؟';

    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: scheme.primary.withAlpha(28),
          child: Text(
            initial,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            request.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// A date over the "how long ago" reading of it — the exact day for the record,
/// the age for the decision the operator is about to make.
///
/// The second line is dropped once [CaptainRequestsFormat.age] stops having an
/// "ago" phrase to offer, rather than repeating the date under itself.
class _DateCell extends StatelessWidget {
  const _DateCell({required this.value, required this.detail});

  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (age != null) ...[
          const SizedBox(height: 2),
          Text(
            age,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Accept and reject, offered only while the request is still open.
///
/// A decided request shows a dash rather than disabled buttons: the decision is
/// already recorded, and there is no re-open flow behind a greyed control to
/// hint at.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final CaptainRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    if (!request.isPending) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final error = context.status(AppStatusTone.error);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'قبول واستكمال البيانات',
          onPressed: onApprove,
          icon: const Icon(Icons.check_circle_outline_rounded),
        ),
        IconButton(
          tooltip: 'رفض الطلب',
          onPressed: onReject,
          color: error.ink,
          icon: const Icon(Icons.cancel_outlined),
        ),
      ],
    );
  }
}

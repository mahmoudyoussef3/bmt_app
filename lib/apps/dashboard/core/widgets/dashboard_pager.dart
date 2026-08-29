import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// The console's one pagination control.
///
/// Lifted out of [OpsDataTable] so the card layouts every list module falls
/// back to on narrow windows page with the *same* control as the table they
/// replace. Three modules used to hand-roll their own — a prev/next icon pair
/// here, a "صفحة ٢ من ٤" label there — so the same list paged differently
/// depending on how wide the window happened to be.
///
/// Compact and numbered: first, last, a window around the current page and an
/// ellipsis between. A page number is a destination the operator can jump
/// straight to; two arrows only ever answer "one step from here".
class DashboardPager extends StatelessWidget {
  const DashboardPager({
    super.key,
    required this.currentPage,
    required this.pages,
    required this.onPageChanged,
  });

  /// Zero-based, like every paged cubit in the console.
  final int currentPage;
  final int pages;
  final ValueChanged<int> onPageChanged;

  /// Which zero-indexed pages to render as buttons, `null` standing in for an
  /// ellipsis. Always includes the first and last page and a window of up to
  /// two neighbours on each side of [currentPage].
  List<int?> _slots() {
    if (pages <= 7) return [for (var i = 0; i < pages; i++) i];

    final slots = <int>{0, pages - 1};
    for (var i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i > 0 && i < pages - 1) slots.add(i);
    }
    final sorted = slots.toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'السابق',
          onPressed: currentPage == 0
              ? null
              : () => onPageChanged(currentPage - 1),
          icon: const Icon(DashboardIcons.paginationPrevious, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        for (final slot in _slots())
          if (slot == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('…'),
            )
          else
            _PageNumberButton(
              page: slot,
              selected: slot == currentPage,
              onTap: () => onPageChanged(slot),
            ),
        IconButton(
          tooltip: 'التالي',
          onPressed: currentPage >= pages - 1
              ? null
              : () => onPageChanged(currentPage + 1),
          icon: const Icon(DashboardIcons.paginationNext, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// [DashboardPager] with the running total beside it — the bar that closes a
/// table or a card list.
class DashboardPagerBar extends StatelessWidget {
  const DashboardPagerBar({
    super.key,
    required this.totalLabel,
    required this.currentPage,
    required this.pages,
    required this.onPageChanged,
  });

  /// Already formatted and worded by the module: "الإجمالي ٤٥ اشتراك".
  final String totalLabel;
  final int currentPage;
  final int pages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    // A [Wrap] rather than a `Row` with a `Spacer`.
    //
    // The row version overflowed at the console's own narrowest declared
    // breakpoint (360px) and got worse with every step of text scale, because
    // nothing in it could yield: two unbounded `Text`s and two fixed 48px
    // buttons in a lane that does not grow. Adding `Flexible` + ellipsis would
    // have stopped the overflow by *deleting the numbers* — and the totals are
    // the entire content of this bar.
    //
    // Wrapping lets the counts drop onto their own lines instead, so a narrow
    // window or 1.6× text costs vertical space rather than information. At
    // normal widths everything still sits on one line, `spaceBetween` holding
    // the total at the start edge and the controls at the end.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      // The bar must fill the row for `spaceBetween` to mean anything: a Wrap
      // under a Column's loose constraints shrink-wraps to its children and
      // then centres the lot, which reads as an accident at desktop widths.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
            DashboardPager(
              currentPage: currentPage,
              pages: pages,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: selected
            ? DashboardColors.accentFill(context)
            : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Text(
                '${page + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? DashboardColors.onHero(context)
                      : DashboardColors.mutedInk(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

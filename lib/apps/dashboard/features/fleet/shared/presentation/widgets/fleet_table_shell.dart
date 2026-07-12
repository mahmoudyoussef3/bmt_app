import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetTableShell extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<int>? columnFlexes;
  final int total;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const FleetTableShell({
    super.key,
    required this.headers,
    required this.rows,
    this.columnFlexes,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = (total / pageSize).ceil().clamp(1, 9999);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: headers.length * 150,
              child: Column(
                children: [
                  Container(
                    color: scheme.surfaceContainerHighest.withAlpha(90),
                    padding: const EdgeInsets.all(AppSpacing.small),
                    child: Row(
                      children: headers
                          .asMap()
                          .entries
                          .map(
                            (e) => Expanded(
                              flex: columnFlexes?[e.key] ?? 1,
                              child: Text(
                                e.value,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.large),
                      child: Text('لا توجد بيانات مطابقة'),
                    )
                  else
                    ...rows.map(
                      (cells) => Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: scheme.outline.withAlpha(90),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: cells
                              .asMap()
                              .entries
                              .map(
                                (e) => Expanded(
                                  flex: columnFlexes?[e.key] ?? 1,
                                  child: e.value,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.small),
            child: Row(
              children: [
                Text('الإجمالي $total'),
                const Spacer(),
                Text('صفحة ${currentPage + 1} من $pages'),
                const SizedBox(width: AppSpacing.small),
                IconButton(
                  onPressed: currentPage == 0
                      ? null
                      : () => onPageChanged(currentPage - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: currentPage >= pages - 1
                      ? null
                      : () => onPageChanged(currentPage + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

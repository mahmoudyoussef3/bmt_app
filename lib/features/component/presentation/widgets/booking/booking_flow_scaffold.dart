import 'package:flutter/material.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';

/// App bar + optional search summary for booking flow screens.
class BookingFlowScaffold extends StatelessWidget {
  const BookingFlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.query,
    this.bottomBar,
    this.actions,
  });

  final String title;
  final Widget body;
  final BookingSearchQuery? query;
  final Widget? bottomBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (query != null && query!.isComplete)
            BookingSearchSummaryBar(query: query!),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

class BookingSearchSummaryBar extends StatelessWidget {
  const BookingSearchSummaryBar({super.key, required this.query});

  final BookingSearchQuery query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withAlpha(100)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              query.summaryLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

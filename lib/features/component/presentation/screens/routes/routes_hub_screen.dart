import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/section_header.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';

/// Routes tab — focused entry into the booking search flow.
class RoutesHubScreen extends StatelessWidget {
  const RoutesHubScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.maxContentWidth(width);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: ListView(
          padding: AppLayout.pagePaddingWithTop,
          children: [
            Text('Routes', style: AppTypography.display(scheme)),
            const SizedBox(height: AppLayout.spaceSm),
            Text(
              'Search, compare, and book your commute',
              style: AppTypography.caption(
                scheme,
              ).copyWith(color: scheme.onSurface.withAlpha(180)),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            AppCard(
              padding: const EdgeInsets.all(AppLayout.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.search_rounded, size: 40, color: scheme.primary),
                  const SizedBox(height: AppLayout.spaceMd),
                  Text(
                    'Where are you going?',
                    style: AppTypography.heading(scheme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppLayout.spaceSm),
                  Text(
                    'Enter pickup, destination, date and time to see available trips.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(
                      scheme,
                    ).copyWith(color: scheme.onSurface.withAlpha(170)),
                  ),
                  const SizedBox(height: AppLayout.spaceLg),
                  AppButton(
                    label: 'Search Trip',
                    height: 52,
                    onPressed: () => onOpenRoute(BookingRoutes.search),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            const SectionHeader(
              title: 'How booking works',
              subtitle: 'A simple path from search to seat',
            ),
            const SizedBox(height: AppLayout.spaceMd),
            _FlowStep(
              step: 1,
              title: 'Search',
              subtitle: 'Pickup, destination, date & time',
            ),
            _FlowStep(
              step: 2,
              title: 'Compare',
              subtitle: 'Routes and vehicles',
            ),
            _FlowStep(
              step: 3,
              title: 'Select seat',
              subtitle: 'Choose your place on board',
            ),
            _FlowStep(
              step: 4,
              title: 'Pay',
              subtitle: 'Secure checkout',
              isLast: true,
            ),
            const SizedBox(height: AppLayout.spaceLg),
            OutlinedButton.icon(
              onPressed: () => onOpenRoute(
                BookingRoutes.popularRoutes,
                const BookingSearchQuery().toArguments(),
              ),
              icon: const Icon(Icons.trending_up_rounded),
              label: const Text('Browse popular routes'),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.step,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primary.withAlpha(50),
                child: Text(
                  '$step',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outline.withAlpha(100),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppLayout.spaceMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppLayout.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subheading(scheme)),
                  Text(subtitle, style: AppTypography.caption(scheme)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

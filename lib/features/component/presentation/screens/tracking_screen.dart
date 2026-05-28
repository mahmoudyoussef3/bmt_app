import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class TrackingScreen extends StatelessWidget {
  final bool shellMode;

  const TrackingScreen({super.key, this.shellMode = false});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, shellMode ? 16 : 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!shellMode)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Tracking',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Real-time vehicle location',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Text(
                    'Live Tracking',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                const SizedBox(height: 12),
                const MapPlaceholder(height: 260),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arriving in',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '7',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontSize: 54,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          'minutes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '8:47 AM',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Expected arrival',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Driver Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const AppAvatar(initials: 'AM', radius: 24),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ahmed Mohamed',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '★★★★★ (4.8)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const AppSeparator(),
                    Row(
                      children: const [
                        Expanded(
                          child: _InfoBox(
                            title: 'Vehicle Number',
                            value: 'MT-2847',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _InfoBox(
                            title: 'Vehicle Type',
                            value: 'Coaster Bus',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Call',
                            outline: true,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Message',
                            outline: true,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Route Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _RouteTimelineCard(
                title: 'Pickup Location',
                subtitle: 'Banha Center',
                detail: 'Departure: 8:30 AM',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              _RouteTimelineCard(
                title: 'Current Location',
                subtitle: 'Ring Road - Nasr City',
                detail: '2.3 km away from destination',
                color: Theme.of(context).colorScheme.tertiary,
                highlight: true,
              ),
              const SizedBox(height: 10),
              _RouteTimelineCard(
                title: 'Destination',
                subtitle: 'Smart Village',
                detail: 'Expected: 8:47 AM',
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Traffic Update',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Light traffic on Ring Road. Maintaining schedule.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RouteTimelineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final Color color;
  final bool highlight;

  const _RouteTimelineCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: highlight
            ? BoxDecoration(
                border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 34,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

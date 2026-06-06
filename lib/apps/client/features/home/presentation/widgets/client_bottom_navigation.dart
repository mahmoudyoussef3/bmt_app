import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';

class ClientBottomNavigation extends StatelessWidget {
  const ClientBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  final String activeTab;
  final ValueChanged<String> onTabChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <({String id, String label, IconData icon})>[
      (id: 'home', label: 'Home', icon: Icons.home_rounded),
      (id: 'routes', label: 'Routes', icon: Icons.route_rounded),
      (id: 'live', label: 'Live Trip', icon: Icons.near_me_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppLayout.spaceMd,
        0,
        AppLayout.spaceMd,
        AppLayout.spaceMd,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(AppLayout.radiusXl),
        border: Border.all(color: scheme.outline.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(34),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceSm,
        vertical: AppLayout.spaceSm,
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab.id;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChange(tab.id),
              borderRadius: BorderRadius.circular(AppLayout.radiusLg),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: AppLayout.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withAlpha(40)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppLayout.radiusLg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 22,
                      color: isActive
                          ? scheme.primary
                          : scheme.onSurface.withAlpha(155),
                    ),
                    const SizedBox(height: AppLayout.spaceXs),
                    Text(
                      tab.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isActive
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(155),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
